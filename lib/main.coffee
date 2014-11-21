NotificationsPanelView = require './notifications-panel-view'
NotificationsElement = require './notifications-element'
NotificationElement = require './notification-element'
{Notification} = require 'atom'

module.exports =
  activate: (state) ->
    @notificationsElement = new NotificationsElement
    atom.views.getView(atom.workspace).appendChild(@notificationsElement)

    atom.notifications.onDidAddNotification (notification) =>
      @notificationsElement.appendChild(atom.views.getView(notification))

    atom.onWillThrowError ({message, url, line, originalError, preventDefault}) ->
      preventDefault()
      options =
        detail: "#{url}:#{line}"
        stack: originalError.stack
        closable: true
      atom.notifications.addFatalError(message, options)

    # TODO: remove this when we are finished developing
    @notificationsPanelView = new NotificationsPanelView(@notificationsElement)
    @notificationsPanel = atom.workspace.addBottomPanel(item: @notificationsPanelView.getElement())

  deactivate: ->
    @notificationsPanel.destroy()
    @notificationsPanelView.destroy()

atom.views.addViewProvider
  modelConstructor: Notification
  viewConstructor: NotificationElement

atom.commands.add 'atom-workspace', 'notifications:trigger-error', ->
  abc + 2 # nope
