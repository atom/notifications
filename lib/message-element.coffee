os = require 'os'
fs = require 'fs'
plist = require 'plist'

class MessageElement extends HTMLElement
  constructor: ->

  getModel: -> @model
  setModel: (@model) ->
    @generateMarkup()
    @autohide() unless @model.isClosable()

  generateMarkup: ->
    @setAttribute('type', @model.type)
    @setAttribute('class', 'icon icon-' + @model.getIcon())

    messageContent = document.createElement('div')
    messageContent.classList.add('content')
    @appendChild(messageContent)

    messageContainer = document.createElement('div')
    messageContainer.classList.add('item')
    messageContainer.classList.add('message')
    messageContainer.textContent = @model.message
    messageContent.appendChild(messageContainer)

    detail = @model.options.detail
    if detail?
      detailContainer = document.createElement('div')
      detailContainer.classList.add('item')
      detailContainer.classList.add('detail')
      messageContent.appendChild(detailContainer)

      for line in detail.split('\n')
        div = document.createElement('div')
        div.textContent = line
        detailContainer.appendChild(div)

    if @model.type is 'fatal'
      fatalContainer = document.createElement('div')
      fatalContainer.classList.add('item')

      fatalMessage = document.createElement('div')
      fatalMessage.classList.add('fatal-message')
      fatalMessage.textContent = 'This is likely a bug in atom. You can help by creating an issue.'

      issueButton = document.createElement('a')
      issueButton.setAttribute('href', @getIssueUrl())
      issueButton.classList.add('btn')
      issueButton.classList.add('btn-error')
      issueButton.textContent = "Create Issue"

      toolbar = document.createElement('div')
      toolbar.classList.add('btn-toolbar')
      toolbar.appendChild(issueButton)

      fatalContainer.appendChild(fatalMessage)
      fatalContainer.appendChild(toolbar)
      messageContent.appendChild(fatalContainer)

    if @model.isClosable()
      @classList.add('has-close')
      closeButton = document.createElement('button')
      closeButton.classList.add('close', 'icon', 'icon-x')
      closeButton.addEventListener 'click', => @handleRemoveMessageClick()
      @appendChild(closeButton)

  handleRemoveMessageClick: =>
    @classList.add('remove')
    @removeMessageAfterTimeout()

  autohide: ->
    setTimeout =>
      @classList.add('remove')
      @removeMessageAfterTimeout()
    , 5000

  removeMessageAfterTimeout: ->
    setTimeout =>
      @remove()
    , 700 # keep in sync with CSS animation

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
    # try
      text = fs.readFileSync('/System/Library/CoreServices/SystemVersion.plist', 'utf8')
      plist.parse(text)
    # catch e
    #   {}

  winVersionText: ->
    info = spawnSync('systeminfo').stdout.toString()
    if (res = /OS.Name.\s+(.*)$/im.exec(info)) then res[1] else 'Unknown Windows Version'

module.exports = MessageElement = document.registerElement 'atom-message', prototype: MessageElement.prototype
