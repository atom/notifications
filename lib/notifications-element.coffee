# A container node for notifications

class NotificationsElement extends HTMLElement
  constructor: ->

module.exports = NotificationsElement = document.registerElement 'atom-notifications', prototype: NotificationsElement.prototype
