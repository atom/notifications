MessagesPanelView = require './messages-panel-view'
MessagesElement = require './messages-element'
Message = require './message'

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

    atom.onWillThrowError ({message, originalError, preventDefault}) ->
      preventDefault()
      atom.messages.add(new Message('fatal', message, originalError.stack))

  deactivate: ->
    @messagesPanel.destroy()
    @messagesPanelView.destroy()



atom.commands.add 'atom-workspace', 'messages:trigger-error', ->
  abc + 2 # nope
