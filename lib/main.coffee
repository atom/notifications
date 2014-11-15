MessagesPanelView = require './messages-panel-view'
MessagesElement = require './messages-element'

class AtomMessagesService
  constructor: (@messagesContainer) ->
  add: (message) ->
    @messagesContainer.appendChild(atom.views.getView(message))

module.exports =
  activate: (state) ->
    @messagesElement = new MessagesElement
    atom.views.getView(atom.workspace).appendChild(@messagesElement)

    atom.messages = new AtomMessagesService(@messagesElement)

    @messagesPanelView = new MessagesPanelView(@messagesElement)
    @messagesPanel = atom.workspace.addBottomPanel(item: @messagesPanelView.getElement())

  deactivate: ->
    @messagesPanel.destroy()
    @messagesPanelView.destroy()
