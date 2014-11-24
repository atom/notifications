os = require 'os'
fs = require 'fs'
plist = require 'plist'

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

    detail = @model.options.detail
    if detail?
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
      fatalNotification.textContent = 'This is likely a bug in atom. You can help by creating an issue.'

      issueButton = document.createElement('a')
      issueButton.setAttribute('href', @getIssueUrl())
      issueButton.classList.add('btn')
      issueButton.classList.add('btn-error')
      issueButton.textContent = "Create Issue"

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

  getIssueUrl: ->
    "https://github.com/atom/atom/issues/new?title=#{encodeURI(@getIssueTitle())}&body=#{encodeURI(@getIssueBody())}"

  getIssueTitle: ->
    @model.getMessage()

  getIssueBody: ->
    options = @model.getOptions()
    """
    There was an unhandled error!

    Atom Version: #{atom.getVersion()}
    System: #{@osMarketingVersion()}

    Stack Trace
    ```
    At #{options.detail}

    #{options.stack}
    ```
    """

  osMarketingVersion: ->
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
