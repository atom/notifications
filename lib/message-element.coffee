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
      issueButton.setAttribute('href', @model.getIssueUrl())
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

module.exports = MessageElement = document.registerElement 'atom-message', prototype: MessageElement.prototype
