{Notification, CompositeDisposable} = require 'atom'

module.exports =
  subscriptions: null

  activate: (state) ->
    NotificationsPanelView = require './notifications-panel-view'
    NotificationsElement = require './notifications-element'
    NotificationElement = require './notification-element'

    @subscriptions = new CompositeDisposable

    atom.views.addViewProvider
      modelConstructor: Notification
      viewConstructor: NotificationElement

    @notificationsElement = new NotificationsElement
    atom.views.getView(atom.workspace).appendChild(@notificationsElement)

    @subscriptions.add atom.notifications.onDidAddNotification (notification) =>
      @notificationsElement.appendChild(atom.views.getView(notification))

    @subscriptions.add atom.onWillThrowError ({message, url, line, originalError, preventDefault}) ->
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
    @subscriptions?.dispose()
    @notificationsElement.remove()

atom.commands.add 'atom-workspace', 'notifications:trigger-error', ->
  abc + 2 # nope
