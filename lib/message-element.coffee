class MessageElement extends HTMLElement
  constructor: ->

  getModel: -> @model
  setModel: (@model) ->
    @setAttribute('type', @model.type)
    @setAttribute('class', 'icon icon-' + @model.icon)
    @textContent = @model.message

    if @model.detail?
      detailContainer = document.createElement('div')
      detailContainer.classList.add('detail')
      @appendChild(detailContainer)

      for line in @model.detail.split('\n')
        div = document.createElement('div')
        div.textContent = line
        detailContainer.appendChild(div)

module.exports = MessageElement = document.registerElement 'atom-message', prototype: MessageElement.prototype
