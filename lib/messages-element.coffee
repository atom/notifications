# A container node for messages

class MessagesElement extends HTMLElement
  constructor: ->

module.exports = MessagesElement = document.registerElement 'atom-messages', prototype: MessagesElement.prototype
