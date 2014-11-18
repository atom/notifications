class MessageElement extends HTMLElement
  constructor: ->

  getModel: -> @model
  setModel: (@model) ->
    @setAttribute('type', @model.type)
    @setAttribute('class', 'icon icon-' + @model.getIcon())
    @textContent = @model.message

    if @model.type == 'fatal'
      @.classList.add('has-close')
      closeButton = document.createElement('button')
      closeButton.classList.add('close', 'icon', 'icon-x')
      @appendChild(closeButton)

    errorDetail = @model.options.errorDetail
    if errorDetail?
      detailContainer = document.createElement('div')
      detailContainer.classList.add('detail')
      @appendChild(detailContainer)

      for line in errorDetail.split('\n')
        div = document.createElement('div')
        div.textContent = line
        detailContainer.appendChild(div)

    if @model.type == 'fatal'
      issueButton = document.createElement('a')
      issueButton.setAttribute('href', @model.getIssueUrl())
      issueButton.classList.add('btn')
      issueButton.classList.add('btn-error')
      issueButton.textContent = "Create Issue"

      toolbar = document.createElement('div')
      toolbar.classList.add('btn-toolbar')
      @appendChild(toolbar)

      toolbar.appendChild(issueButton)

  createIssue: ->
    console.log 'issue', @model


module.exports = MessageElement = document.registerElement 'atom-message', prototype: MessageElement.prototype
