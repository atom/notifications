class MessageElement extends HTMLElement
  constructor: ->

  getModel: -> @model
  setModel: (@model) ->
    @setAttribute('type', @model.type)
    @textContent = @model.message

module.exports = MessageElement = document.registerElement 'atom-message', prototype: MessageElement.prototype
