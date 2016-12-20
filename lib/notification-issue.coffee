fs = require 'fs'
request = require 'request'
path = require 'path'
StackTraceParser = require 'stacktrace-parser'

CommandLogger = require './command-logger'
UserUtilities = require './user-utilities'

TITLE_CHAR_LIMIT = 100 # Truncate issue title to 100 characters (including ellipsis)

FileURLRegExp = new RegExp('file://\w*/(.*)')

module.exports =
class NotificationIssue
  constructor: (@notification) ->

  findSimilarIssues: ->
    url = "https://api.github.com/search/issues"
    repoUrl = @getRepoUrl()
    repoUrl = 'atom/atom' unless repoUrl?
    repo = repoUrl.replace /http(s)?:\/\/(\d+\.)?github.com\//gi, ''
    query = "#{@getIssueTitle()} repo:#{repo}"

    new Promise (resolve, reject) =>
      request.get {
        uri: "#{url}?q=#{encodeURI(query)}&sort=created",
        headers: {
          accept: 'application/vnd.github.v3+json'
          contentType: "application/json"
        }
      }, (err, resp, body) =>
        resolve(null) if err?

        if body.items?
          issues = {}
          for issue in body.items
            if issue.title.indexOf(@getIssueTitle()) > -1 and not issues[issue.state]?
              issues[issue.state] = issue
              break

          return resolve(issues) if issues.open? or issues.closed?
        resolve(null)

  getIssueUrlForSystem: ->
    new Promise (resolve, reject) =>
      @getIssueUrl().then (issueUrl) ->
        request.post {
          uri: 'https://is.gd/create.php?format=simple'
          form: {url: issueUrl},
        },
        (err, resp, body) ->
          resolve(issueUrl) if err
          resolve(body)
      return

  getIssueUrl: ->
    @getIssueBody().then (issueBody) =>
      repoUrl = @getRepoUrl()
      repoUrl = 'https://github.com/atom/atom' unless repoUrl?
      "#{repoUrl}/issues/new?title=#{encodeURIComponent(@getIssueTitle())}&body=#{encodeURIComponent(issueBody)}"

  getIssueTitle: ->
    title = @notification.getMessage()
    title = title.replace(process.env.ATOM_HOME, '$ATOM_HOME')
    if process.platform is 'win32'
      title = title.replace(process.env.USERPROFILE, '~')
      title = title.replace(path.sep, path.posix.sep) # Standardize issue titles
    else
      title = title.replace(process.env.HOME, '~')

    if title.length > TITLE_CHAR_LIMIT
      title = title.substring(0, TITLE_CHAR_LIMIT - 3) + '...'
    title

  getIssueBody: ->
    new Promise (resolve, reject) =>
      return resolve(@issueBody) if @issueBody
      systemPromise = UserUtilities.getOSVersion()
      installedPackagesPromise = UserUtilities.getInstalledPackages()

      Promise.all([systemPromise, installedPackagesPromise]).then (all) =>
        [systemName, installedPackages] = all

        message = @notification.getMessage()
        options = @notification.getOptions()
        repoUrl = @getRepoUrl()
        packageName = @getPackageName()
        packageVersion = atom.packages.getLoadedPackage(packageName)?.metadata?.version if packageName?
        userConfig = UserUtilities.getConfigForPackage(packageName)
        copyText = ''
        systemUser = process.env.USER
        rootUserStatus = ''

        if systemUser is 'root'
          rootUserStatus = '**User**: root'

        if packageName? and repoUrl?
          packageMessage = "[#{packageName}](#{repoUrl}) package, v#{packageVersion}"
        else if packageName?
          packageMessage = "'#{packageName}' package, v#{packageVersion}"
        else
          packageMessage = 'Atom Core'

        atomVersion = atom.getVersion()
        electronVersion = process.versions.electron

        @issueBody = """
          [Enter steps to reproduce below:]

          1. ...
          2. ...

          **Atom Version**: #{atomVersion}
          **Electron Version**: #{electronVersion}
          **System**: #{systemName}
          **Thrown From**: #{packageMessage}
          #{rootUserStatus}

          ### Stack Trace

          #{message}

          ```
          At #{options.detail}

          #{options.stack}
          ```

          ### Commands

          #{CommandLogger.instance().getText()}

          ### Config

          ```json
          #{JSON.stringify(userConfig, null, 2)}
          ```

          ### Installed Packages

          ```coffee
          # User
          #{installedPackages.user.join('\n') or 'No installed packages'}

          # Dev
          #{installedPackages.dev.join('\n') or 'No dev packages'}
          ```

          #{copyText}
        """
        resolve(@issueBody)

  getRepoUrl: ->
    packageName = @getPackageName()
    return unless packageName?
    repo = atom.packages.getLoadedPackage(packageName)?.metadata?.repository
    repoUrl = repo?.url ? repo
    unless repoUrl
      if packagePath = atom.packages.resolvePackagePath(packageName)
        try
          repo = JSON.parse(fs.readFileSync(path.join(packagePath, 'package.json')))?.repository
          repoUrl = repo?.url ? repo

    repoUrl?.replace(/\.git$/, '').replace(/^git\+/, '')

  getPackageNameFromFilePath: (filePath) ->
    return unless filePath

    packageName = /\/\.atom\/dev\/packages\/([^\/]+)\//.exec(filePath)?[1]
    return packageName if packageName

    packageName = /\\\.atom\\dev\\packages\\([^\\]+)\\/.exec(filePath)?[1]
    return packageName if packageName

    packageName = /\/\.atom\/packages\/([^\/]+)\//.exec(filePath)?[1]
    return packageName if packageName

    packageName = /\\\.atom\\packages\\([^\\]+)\\/.exec(filePath)?[1]
    return packageName if packageName

  getPackageName: ->
    options = @notification.getOptions()

    return options.packageName if options.packageName?
    return unless options.stack? or options.detail?

    packagePaths = @getPackagePathsByPackageName()
    for packageName, packagePath of packagePaths
      if packagePath.indexOf(path.join('.atom', 'dev', 'packages')) > -1 or packagePath.indexOf(path.join('.atom', 'packages')) > -1
        packagePaths[packageName] = fs.realpathSync(packagePath)

    getPackageName = (filePath) =>
      filePath = /\((.+?):\d+|\((.+)\)|(.+)/.exec(filePath)[0]

      # Stack traces may be a file URI
      if match = FileURLRegExp.exec(filePath)
        filePath = match[1]

      filePath = path.normalize(filePath)

      if path.isAbsolute(filePath)
        for packName, packagePath of packagePaths
          continue if filePath is 'node.js'
          isSubfolder = filePath.indexOf(path.normalize(packagePath + path.sep)) is 0
          return packName if isSubfolder
      @getPackageNameFromFilePath(filePath)

    if options.detail? and packageName = getPackageName(options.detail)
      return packageName

    if options.stack?
      stack = StackTraceParser.parse(options.stack)
      for i in [0...stack.length]
        {file} = stack[i]

        # Empty when it was run from the dev console
        return unless file
        packageName = getPackageName(file)
        return packageName if packageName?

    return

  getPackagePathsByPackageName: ->
    packagePathsByPackageName = {}
    for pack in atom.packages.getLoadedPackages()
      packagePathsByPackageName[pack.name] = pack.path
    packagePathsByPackageName
