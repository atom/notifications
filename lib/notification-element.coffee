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

  initialize: (@model) ->
    @generateMarkup()
    if @model.isDismissable()
      @model.onDidDismiss => @removeNotification()
    else
      @autohide()
    this

  getModel: -> @model

  generateMarkup: ->
    # OMG we need a data-binding framework
    @classList.add "#{@model.getType()}"
    @classList.add "icon", "icon-#{@model.getIcon()}", "native-key-bindings"

    @setAttribute('tabindex', '-1')

    notificationContent = document.createElement('div')
    notificationContent.classList.add('content')
    @appendChild(notificationContent)

    notificationContainer = document.createElement('div')
    notificationContainer.classList.add('item')
    notificationContainer.classList.add('message')
    notificationContainer.textContent = @model.getMessage()
    notificationContent.appendChild(notificationContainer)

    if detail = @model.getDetail()
      addSplitLinesToContainer = (container, content) ->
        for line in content.split('\n')
          div = document.createElement('div')
          div.classList.add 'line'
          div.textContent = line
          container.appendChild(div)
        return

      @classList.add('has-detail')
      detailContainer = document.createElement('div')
      detailContainer.classList.add('item')
      detailContainer.classList.add('detail')
      addSplitLinesToContainer(detailContainer, detail)
      notificationContent.appendChild(detailContainer)

      if stack = @model.getOptions().stack
        stackToggle = document.createElement('a')
        stackContainer = document.createElement('div')

        stackToggle.setAttribute('href', '#')
        stackToggle.classList.add 'stack-toggle'
        stackToggle.addEventListener 'click', (e) => @handleStackTraceToggleClick(e, stackContainer)

        stackContainer.classList.add 'stack-container'
        addSplitLinesToContainer(stackContainer, stack)

        detailContainer.appendChild(stackToggle)
        detailContainer.appendChild(stackContainer)
        @handleStackTraceToggleClick({target: stackToggle}, stackContainer)

    if @model.type is 'fatal'
      fatalContainer = document.createElement('div')
      fatalContainer.classList.add('item')

      fatalNotification = document.createElement('div')
      fatalNotification.classList.add('fatal-notification')

      repoUrl = @getRepoUrl()
      packageName = @getPackageName()
      if packageName? and repoUrl?
        fatalNotification.innerHTML = "The error was thrown from the <a href=\"#{repoUrl}\">#{packageName} package</a>"
      else if packageName?
        fatalNotification.textContent = 'The error was thrown from the #{packageName} package, but it may be a bug in Atom core.'
      else
        fatalNotification.textContent = 'This is likely a bug in Atom.'

      issueButton = document.createElement('a')
      issueButton.setAttribute('href', @getIssueUrl())
      issueButton.classList.add('btn')
      issueButton.classList.add('btn-error')
      if packageName? and repoUrl?
        issueButton.textContent = "Create issue on the #{packageName} package"
      else
        issueButton.textContent = "Create issue on atom/atom"
      @fetchIssue (issue) ->
        if issue?
          issueButton.setAttribute('href', issue.html_url)
          issueButton.textContent = "View Issue"
          fatalNotification.textContent += " This issue has already been reported."
        else
          fatalNotification.textContent += " You can help by creating an issue. Please explain what actions triggered this error."

      toolbar = document.createElement('div')
      toolbar.classList.add('btn-toolbar')
      toolbar.appendChild(issueButton)

      fatalContainer.appendChild(fatalNotification)
      fatalContainer.appendChild(toolbar)
      notificationContent.appendChild(fatalContainer)

    if @model.isDismissable()
      @classList.add('has-close')
      closeButton = document.createElement('button')
      closeButton.classList.add('close', 'icon', 'icon-x')
      closeButton.addEventListener 'click', => @handleRemoveNotificationClick()
      @appendChild(closeButton)

      closeAllButton = document.createElement('button')
      closeAllButton.textContent = 'Close All'
      closeAllButton.classList.add('close-all', 'btn', @getButtonClass())
      closeAllButton.addEventListener 'click', => @handleRemoveAllNotificationsClick()
      @appendChild(closeAllButton)

  removeNotification: ->
    @classList.add('remove')
    @removeNotificationAfterTimeout()

  handleRemoveNotificationClick: ->
    @model.dismiss()

  handleRemoveAllNotificationsClick: ->
    notifications = atom.notifications.getNotifications()
    for notification in notifications
      if notification.isDismissable() and not notification.isDismissed()
        notification.dismiss()
    return

  handleStackTraceToggleClick: (e, container) ->
    e.preventDefault?()
    if container.style.display is 'none'
      e.target.innerHTML = '<span class="icon icon-dash"></span>Hide Stack Trace'
      container.style.display = 'block'
    else
      e.target.innerHTML = '<span class="icon icon-plus"></span>Show Stack Trace'
      container.style.display = 'none'

  autohide: ->
    setTimeout =>
      @classList.add('remove')
      @removeNotificationAfterTimeout()
    , @visibilityDuration

  removeNotificationAfterTimeout: ->
    setTimeout =>
      @remove()
    , @animationDuration # keep in sync with CSS animation

  getButtonClass: ->
    type = "btn-#{@model.getType()}"
    if type == 'btn-fatal' then 'btn-error' else type

  fetchIssue: (callback) ->
    url = "https://api.github.com/search/issues"
    repoUrl = @getRepoUrl()
    repoUrl = 'atom/atom' unless repoUrl?
    repo = repoUrl.replace /http(s)?:\/\/(\d+\.)?github.com\//gi, ''
    query = "#{@getIssueTitle()} repo:#{repo} state:open"

    $.ajax "#{url}?q=#{encodeURI(query)}&sort=created",
      accept: 'application/vnd.github.v3+json'
      contentType: "application/json"
      success: (data) =>
        if data.items?
          for issue in data.items
            return callback?(issue) if issue.title.indexOf(@getIssueTitle()) > -1
        callback?(null)

  getIssueUrl: ->
    repoUrl = @getRepoUrl()
    repoUrl = 'https://github.com/atom/atom' unless repoUrl?
    "#{repoUrl}/issues/new?title=#{@encodeURI(@getIssueTitle())}&body=#{@encodeURI(@getIssueBody())}"

  getIssueTitle: ->
    @model.getMessage()

  getIssueBody: ->
    options = @model.getOptions()
    repoUrl = @getRepoUrl()
    packageName = @getPackageName()
    packageVersion = atom.packages.getActivePackage(packageName)?.metadata?.version if packageName?
    copyText = ''
    copyText = '/cc @atom/core' if packageName? and repoUrl?

    if packageName? and repoUrl?
      packageMessage = "[#{packageName}](#{repoUrl}) package, v#{packageVersion}"
    else if packageName?
      packageMessage = "'#{packageName}' package, v#{packageVersion}"
    else
      packageMessage = 'Atom Core'

    """
    #{@model.getMessage()}

    **Atom Version**: #{atom.getVersion()}
    **System**: #{@getOSMarketingVersion()}
    **Thrown From**: #{packageMessage}

    ### Steps To Reproduce

    1. ...
    2. ...

    ### Stack Trace

    ```
    At #{options.detail}

    #{options.stack}
    ```

    #{copyText}
    """

  encodeURI: (str) ->
    str = encodeURI(str)
    str.replace(/#/g, '%23')

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
