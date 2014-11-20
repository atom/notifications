MessagesPanelView = require './messages-panel-view'
MessagesElement = require './messages-element'
MessageElement = require './message-element'
{Message} = require 'atom'

module.exports =
  activate: (state) ->
    @messagesElement = new MessagesElement
    atom.views.getView(atom.workspace).appendChild(@messagesElement)

    atom.messages.onDidAddMessage (message) =>
      @messagesElement.appendChild(atom.views.getView(message))

    atom.onWillThrowError ({message, url, line, originalError, preventDefault}) ->
      preventDefault()
      options =
        detail: "#{url}:#{line}"
        stack: originalError.stack
        closable: true
      atom.messages.addFatalError(message, options)

    # TODO: remove this when we are finished developing
    @messagesPanelView = new MessagesPanelView(@messagesElement)
    @messagesPanel = atom.workspace.addBottomPanel(item: @messagesPanelView.getElement())

  deactivate: ->
    @messagesPanel.destroy()
    @messagesPanelView.destroy()

atom.views.addViewProvider
  modelConstructor: Message
  viewConstructor: MessageElement

atom.commands.add 'atom-workspace', 'messages:trigger-error', ->
  abc + 2 # nope
