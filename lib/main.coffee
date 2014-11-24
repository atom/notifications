{Notification, CompositeDisposable} = require 'atom'

Notifications =
  subscriptions: null

  activate: (state) ->
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

  deactivate: ->
    @subscriptions?.dispose()
    @notificationsElement.remove()
    @notificationsPanel?.destroy()

  togglePanel: ->
    if @notificationsPanel?
      if Notifications.notificationsPanel.isVisible()
        Notifications.notificationsPanel.hide()
      else
        Notifications.notificationsPanel.show()
    else
      NotificationsPanelView = require './notifications-panel-view'
      Notifications.notificationsPanelView = new NotificationsPanelView
      Notifications.notificationsPanel = atom.workspace.addBottomPanel(item: Notifications.notificationsPanelView.getElement())

if atom.inDevMode()
  atom.commands.add 'atom-workspace', 'notifications:toggle-dev-panel', -> Notifications.togglePanel()
  atom.commands.add 'atom-workspace', 'notifications:trigger-error', -> abc + 2 # nope

module.exports = Notifications
