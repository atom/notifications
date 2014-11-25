os = require 'os'
fs = require 'fs'
path = require 'path'
plist = require 'plist'
StackTraceParser = require 'stacktrace-parser'
$ = require 'jquery'

class NotificationElement extends HTMLElement
  animationDuration: 700
  visibilityDuration: 5000

  constructor: ->

  getModel: -> @model
  setModel: (@model) ->
    @generateMarkup()
    @autohide() unless @model.isClosable()

  generateMarkup: ->
    @classList.add "#{@model.getType()}"
    @classList.add "icon"
    @classList.add "icon-#{@model.getIcon()}"

    notificationContent = document.createElement('div')
    notificationContent.classList.add('content')
    @appendChild(notificationContent)

    notificationContainer = document.createElement('div')
    notificationContainer.classList.add('item')
    notificationContainer.classList.add('message')
    notificationContainer.textContent = @model.getMessage()
    notificationContent.appendChild(notificationContainer)

    detail = @model.getDetail()
    if detail?
      @classList.add('has-detail')
      detailContainer = document.createElement('div')
      detailContainer.classList.add('item')
      detailContainer.classList.add('detail')
      notificationContent.appendChild(detailContainer)

      for line in detail.split('\n')
        div = document.createElement('div')
        div.textContent = line
        detailContainer.appendChild(div)

    if @model.type is 'fatal'
      fatalContainer = document.createElement('div')
      fatalContainer.classList.add('item')

      fatalNotification = document.createElement('div')
      fatalNotification.classList.add('fatal-notification')

      repoUrl = @getRepoUrl()
      packageName = @getPackageName()
      if packageName? and repoUrl?
        fatalNotification.innerHTML = "The error was thrown from the <a href=\"#{repoUrl}\">#{packageName} package</a>, but it may be a bug in Atom."
      else if packageName?
        fatalNotification.textContent = 'The error was thrown from the #{packageName} package, but it might be a bug in Atom core.'
      else
        fatalNotification.textContent = 'This is likely a bug in Atom.'

      issueButton = document.createElement('a')
      issueButton.setAttribute('href', @getIssueUrl())
      issueButton.classList.add('btn')
      issueButton.classList.add('btn-error')
      issueButton.textContent = "Create Issue On atom/atom"
      @fetchIssue (issue) ->
        if issue?
          issueButton.setAttribute('href', issue.html_url)
          issueButton.textContent = "View Issue"
          fatalNotification.textContent += " This issue has already been reported."
        else
          fatalNotification.textContent += " You can help by creating an issue."

      toolbar = document.createElement('div')
      toolbar.classList.add('btn-toolbar')
      toolbar.appendChild(issueButton)

      fatalContainer.appendChild(fatalNotification)
      fatalContainer.appendChild(toolbar)
      notificationContent.appendChild(fatalContainer)

    if @model.isClosable()
      @classList.add('has-close')
      closeButton = document.createElement('button')
      closeButton.classList.add('close', 'icon', 'icon-x')
      closeButton.addEventListener 'click', => @handleRemoveNotificationClick()
      @appendChild(closeButton)

  handleRemoveNotificationClick: ->
    @classList.add('remove')
    @removeNotificationAfterTimeout()

  autohide: ->
    setTimeout =>
      @classList.add('remove')
      @removeNotificationAfterTimeout()
    , @visibilityDuration

  removeNotificationAfterTimeout: ->
    setTimeout =>
      @remove()
    , @animationDuration # keep in sync with CSS animation

  fetchIssue: (callback) ->
    url = "https://api.github.com/search/issues"
    query = "#{@getIssueTitle()} repo:atom/atom state:open"

    $.ajax "#{url}?q=#{encodeURI(query)}&sort=created",
      accept: 'application/vnd.github.v3+json'
      contentType: "application/json"
      success: (data) ->
        issue = data.items?[0]
        callback?(issue)

  getIssueUrl: ->
    "https://github.com/atom/atom/issues/new?title=#{encodeURI(@getIssueTitle())}&body=#{encodeURI(@getIssueBody())}"

  getIssueTitle: ->
    @model.getMessage()

  getIssueBody: ->
    options = @model.getOptions()
    repoUrl = @getRepoUrl()
    packageName = @getPackageName()

    if packageName? and repoUrl?
      packageMessage = "[#{packageName}](#{repoUrl}) package"
    else if packageName?
      packageMessage = "'#{packageName}' package"
    else
      packageMessage = 'Atom Core'

    """
    There was an unhandled error!

    Atom Version: #{atom.getVersion()}
    System: #{@getOSMarketingVersion()}
    Thrown From: #{packageMessage}

    Stack Trace
    ```
    At #{options.detail}

    #{options.stack}
    ```
    """

  getRepoUrl: ->
    packageName = @getPackageName()
    return unless packageName?
    repo = atom.packages.getActivePackage(packageName)?.metadata?.repository
    repoUrl = repo?.url ? repo
    repoUrl = repoUrl?.replace(/\.git$/, '')
    repoUrl

  getPackageName: ->
    options = @model.getOptions()
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
    return @packagePathsByPackageName if @packagePathsByPackageName?
    @packagePathsByPackageName = {}
    for pack in atom.packages.getLoadedPackages()
      @packagePathsByPackageName[pack.name] = pack.path
    @packagePathsByPackageName

  # OS version strings lifted from https://github.com/lee-dohm/bug-report
  getOSMarketingVersion: ->
    switch os.platform()
      when 'darwin' then @macVersionText()
      when 'win32' then @winVersionText()
      else "#{os.platform()} #{os.release()}"

  macVersionText: (info = @macVersionInfo()) ->
    return 'Unknown OS X version' unless info.ProductName and info.ProductVersion

    "#{info.ProductName} #{info.ProductVersion}"

  macVersionInfo: ->
    try
      text = fs.readFileSync('/System/Library/CoreServices/SystemVersion.plist', 'utf8')
      plist.parse(text)
    catch e
      {}

  winVersionText: ->
    info = spawnSync('systeminfo').stdout.toString()
    if (res = /OS.Name.\s+(.*)$/im.exec(info)) then res[1] else 'Unknown Windows Version'

module.exports = NotificationElement = document.registerElement 'atom-notification', prototype: NotificationElement.prototype
