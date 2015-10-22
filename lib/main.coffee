{Notification, CompositeDisposable} = require 'atom'
fs = require 'fs-plus'
StackTraceParser = null

Notifications =
  isInitialized: false
  subscriptions: null
  duplicateTimeDelay: 500
  lastNotification: null

  config:
    showErrorsInDevMode:
      type: 'boolean'
      default: false
      description: 'Show notifications for uncaught exceptions even if Atom is running in dev mode. If this config setting is disabled, uncaught exceptions will trigger the dev tools to open and be logged in the console tab.'

  activate: (state) ->
    CommandLogger = require './command-logger'
    CommandLogger.start()
    @subscriptions = new CompositeDisposable

    @addNotificationView(notification) for notification in atom.notifications.getNotifications()
    @subscriptions.add atom.notifications.onDidAddNotification (notification) => @addNotificationView(notification)

    @subscriptions.add atom.onWillThrowError ({message, url, line, originalError, preventDefault}) ->
      if originalError.name is 'BufferedProcessError'
        message = message.replace('Uncaught BufferedProcessError: ', '')
        atom.notifications.addError(message, dismissable: true)

      else if originalError.code is 'ENOENT' and not /\/atom/i.test(message) and match = /spawn (.+) ENOENT/.exec(message)
        message = """
          '#{match[1]}' could not be spawned.
          Is it installed and on your path?
          If so please open an issue on the package spawning the process.
        """
        atom.notifications.addError(message, dismissable: true)

      else if not atom.inDevMode() or atom.config.get('notifications.showErrorsInDevMode')
        preventDefault()

        # Ignore errors with no paths in them since they are impossible to trace
        if originalError.stack and not isCoreOrPackageStackTrace(originalError.stack)
          return

        options =
          detail: "#{url}:#{line}"
          stack: originalError.stack
          dismissable: true
        atom.notifications.addFatalError(message, options)

    @subscriptions.add atom.commands.add 'atom-workspace', 'core:cancel', ->
      notification.dismiss() for notification in atom.notifications.getNotifications()

  deactivate: ->
    @subscriptions.dispose()
    @notificationsElement?.remove()
    @notificationsPanel?.destroy()

    @subscriptions = null
    @notificationsElement = null
    @notificationsPanel = null

    @isInitialized = false

  initializeIfNotInitialized: ->
    return if @isInitialized

    NotificationsElement = require './notifications-element'
    NotificationElement = require './notification-element'

    @subscriptions.add atom.views.addViewProvider Notification, (model) ->
      new NotificationElement().initialize(model)

    @notificationsElement = new NotificationsElement
    atom.views.getView(atom.workspace).appendChild(@notificationsElement)

    @isInitialized = true

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

  addNotificationView: (notification) ->
    return unless notification?
    @initializeIfNotInitialized()
    return if notification.wasDisplayed()

    if @lastNotification?
      # do not show duplicates unless some amount of time has passed
      timeSpan = notification.getTimestamp() - @lastNotification.getTimestamp()
      unless timeSpan < @duplicateTimeDelay and notification.isEqual(@lastNotification)
        @notificationsElement.appendChild(atom.views.getView(notification))
    else
      @notificationsElement.appendChild(atom.views.getView(notification))

    notification.setDisplayed(true)
    @lastNotification = notification

isCoreOrPackageStackTrace = (stack) ->
  StackTraceParser ?= require 'stacktrace-parser'
  for {file} in StackTraceParser.parse(stack)
    return true if fs.isAbsolute(file)
  false

if atom.inDevMode()
  atom.commands.add 'atom-workspace', 'notifications:toggle-dev-panel', -> Notifications.togglePanel()
  atom.commands.add 'atom-workspace', 'notifications:trigger-error', ->
    try
      abc + 2 # nope
    catch error
      options =
        detail: error.stack.split('\n')[1]
        stack: error.stack
        dismissable: true
      atom.notifications.addFatalError("Uncaught #{error.stack.split('\n')[0]}", options)

module.exports = Notifications
