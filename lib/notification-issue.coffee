$ = require 'jquery'
fs = require 'fs'
path = require 'path'
StackTraceParser = require 'stacktrace-parser'

CommandLogger = require './command-logger'
UserUtilities = require './user-utilities'

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
              issues[issue.state] = issue if issue.title.indexOf(@getIssueTitle()) > -1 and not issues[issue.state]?
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
    @notification.getMessage()

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

        if packageName? and repoUrl?
          packageMessage = "[#{packageName}](#{repoUrl}) package, v#{packageVersion}"
        else if packageName?
          packageMessage = "'#{packageName}' package, v#{packageVersion}"
        else
          packageMessage = 'Atom Core'

        @issueBody = """
          [Enter steps to reproduce below:]

          1. ...
          2. ...

          **Atom Version**: #{atom.getVersion()}
          **System**: #{systemName}
          **Thrown From**: #{packageMessage}

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
    repoUrl = repoUrl?.replace(/\.git$/, '')
    repoUrl

  getPackageName: ->
    options = @notification.getOptions()
    return unless options.stack?
    stack = StackTraceParser.parse(options.stack)

    packagePaths = @getPackagePathsByPackageName()
    for packageName, packagePath of packagePaths
      if packagePath.indexOf('.atom/dev/packages') > -1 or packagePath.indexOf('.atom/packages') > -1
        packagePaths[packageName] = fs.realpathSync(packagePath)

    for i in [0...stack.length]
      {file} = stack[i]

      # Empty when it was run from the dev console
      return unless file

      for packageName, packagePath of packagePaths
        continue if file is 'node.js'
        relativePath = path.relative(packagePath, file)
        return packageName unless /^\.\./.test(relativePath)
    return

  getPackagePathsByPackageName: ->
    packagePathsByPackageName = {}
    for pack in atom.packages.getLoadedPackages()
      packagePathsByPackageName[pack.name] = pack.path
    packagePathsByPackageName
