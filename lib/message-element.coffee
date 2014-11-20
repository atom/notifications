class MessageElement extends HTMLElement
  constructor: ->

  getModel: -> @model
  setModel: (@model) ->
    @setAttribute('type', @model.type)
    @setAttribute('class', 'icon icon-' + @model.getIcon())

    messageContainer = document.createElement('div')
    messageContainer.classList.add('item')
    messageContainer.classList.add('message')
    messageContainer.textContent = @model.message
    @appendChild(messageContainer)

    errorDetail = @model.options.errorDetail
    if errorDetail?
      detailContainer = document.createElement('div')
      detailContainer.classList.add('item')
      detailContainer.classList.add('detail')
      @appendChild(detailContainer)

      for line in errorDetail.split('\n')
        div = document.createElement('div')
        div.textContent = line
        detailContainer.appendChild(div)

    if @model.type == 'fatal'

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

      @.classList.add('has-close')
      closeButton = document.createElement('button')
      closeButton.classList.add('close', 'icon', 'icon-x')
      closeButton.addEventListener 'click', @removeMessage

      fatalContainer.appendChild(fatalMessage)
      fatalContainer.appendChild(toolbar)
      @appendChild(fatalContainer)
      @appendChild(closeButton)

  createIssue: ->
    console.log 'issue', @model

  removeMessage: (e) ->
    e.target.parentElement.classList.add('remove')
    setTimeout (-> e.target.parentElement.remove() ), 700 # keep in sync with CSS animation


module.exports = MessageElement = document.registerElement 'atom-message', prototype: MessageElement.prototype
