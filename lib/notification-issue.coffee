$ = require 'jquery'
fs = require 'fs'
path = require 'path'
StackTraceParser = require 'stacktrace-parser'

CommandLogger = require './command-logger'
UserUtilities = require './user-utilities'

TITLE_CHAR_LIMIT = 100 # Truncate issue title to 100 characters (including ellipsis)

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
      $.ajax "#{url}?q=#{encodeURI(query)}&sort=created",
        accept: 'application/vnd.github.v3+json'
        contentType: "application/json"
        success: (data) =>
          if data.items?
            issues = {}
            for issue in data.items
              if issue.title.indexOf(@getIssueTitle()) > -1 and not issues[issue.state]?
                issues[issue.state] = issue
                break

            return resolve(issues) if issues.open? or issues.closed?
          resolve(null)
        error: -> resolve(null)

  getIssueUrlForSystem: ->
    new Promise (resolve, reject) =>
      @getIssueUrl().then (issueUrl) ->
        if UserUtilities.getPlatform() is 'win32'
          # win32 can only handle a 2048 length link, so we use the shortener.
          $.ajax 'http://git.io',
            type: 'POST'
            data: url: issueUrl
            success: (data, status, xhr) ->
              resolve(xhr.getResponseHeader('Location'))
            error: -> resolve(issueUrl)
        else
          resolve(issueUrl)
      return

  getIssueUrl: ->
    @getIssueBody().then (issueBody) =>
      repoUrl = @getRepoUrl()
      repoUrl = 'https://github.com/atom/atom' unless repoUrl?
      "#{repoUrl}/issues/new?title=#{@encodeURI(@getIssueTitle())}&body=#{@encodeURI(issueBody)}"

  getIssueTitle: ->
    title = @notification.getMessage()
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
        if atom.getLoadSettings().apiPreviewMode
          atomVersion += " :warning: **in 1.0 API Preview Mode** :warning:"

        @issueBody = """
          [Enter steps to reproduce below:]

          1. ...
          2. ...

          **Atom Version**: #{atomVersion}
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

  encodeURI: (str) ->
    str = encodeURI(str)
    str.replace(/#/g, '%23').replace(/;/g, '%3B')

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
    message = @notification.getMessage()
    options = @notification.getOptions()
    return unless message? or options.stack? or options.detail?

    packagePaths = @getPackagePathsByPackageName()
    for packageName, packagePath of packagePaths
      if packagePath.indexOf(path.join('.atom', 'dev', 'packages')) > -1 or packagePath.indexOf(path.join('.atom', 'packages')) > -1
        packagePaths[packageName] = fs.realpathSync(packagePath)

    getPackageName = (filePath) =>
      if path.isAbsolute(filePath)
        for packName, packagePath of packagePaths
          continue if filePath is 'node.js'
          relativePath = path.relative(packagePath, filePath)
          return packName unless /^\.\./.test(relativePath)
      @getPackageNameFromFilePath(filePath)

    packageName = /Failed to (load|activate) the (.*) package/.exec(message)?[2]
    return packageName if packageName?

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
