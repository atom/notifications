{Emitter, CompositeDisposable, Disposable} = require 'atom'
moment = require 'moment'

module.exports = class NotificationsLogItem
  timestampTimeout: null

  constructor: (@notification) ->
    @emitter = new Emitter
    @disposables = new CompositeDisposable
    @disposables.add new Disposable => clearTimeout @timestampTimeout
    @updateTimestamp = @updateTimestamp.bind(this)
    @render()

  render: ->
    notificationView = atom.views.getView(@notification)
    notificationElement = @renderNotification(notificationView)

    if @notification.getType() is 'fatal'
      notificationView.getRenderPromise().then =>
        @element.replaceChild(@renderNotification(notificationView), notificationElement)

    @timestamp = document.createElement('div')
    @timestamp.classList.add('timestamp')
    @notification.moment = moment(@notification.getTimestamp())
    @disposables.add atom.tooltips.add(@timestamp, title: @notification.moment.format("ll LTS"))
    @updateTimestamp()

    @element = document.createElement('li')
    @element.classList.add('notifications-log-item', @notification.getType())
    @element.appendChild(notificationElement)
    @element.appendChild(@timestamp)
    @element.addEventListener 'click', (e) =>
      if not e.target.closest('.btn-toolbar')?
        @emitter.emit 'click'

    @disposables.add new Disposable => @element.remove()

  renderNotification: (view) ->
    message = document.createElement('div')
    message.classList.add('message')
    message.innerHTML = view.element.querySelector(".content > .message").innerHTML

    buttons = document.createElement('div')
    buttons.classList.add('btn-toolbar')
    nButtons = view.element.querySelector(".content > .meta > .btn-toolbar")
    if nButtons?
      for button in nButtons.children
        logButton = button.cloneNode(true)
        logButton.originalButton = button
        logButton.addEventListener 'click', (e) ->
          newEvent = new MouseEvent('click', e)
          e.target.originalButton.dispatchEvent(newEvent)
        if button.classList.contains('btn-copy-report')
          @disposables.add atom.tooltips.add(logButton, title: 'Copy error report to clipboard')
        buttons.appendChild(logButton)

    nElement = document.createElement('div')
    nElement.classList.add('notifications-log-notification', 'icon', "icon-#{@notification.getIcon()}", @notification.getType())
    nElement.appendChild(message)
    nElement.appendChild(buttons)
    nElement

  getElement: -> @element

  destroy: ->
    @disposables.dispose()
    @emitter.emit 'did-destroy'

  onClick: (callback) ->
    @emitter.on 'click', callback

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  updateTimestamp: ->
    ms = 0 - @notification.moment.diff()
    sec = Math.round(ms / 1000)
    min = Math.round(sec / 60)
    hr = Math.round(min / 60)
    day = Math.round(hr / 24)

    switch
      when ms < 0 # in the future
        timeout = 1000 # 1 second
      when sec < 45 # a few seconds ago
        timeout = 45 * 1000 # 45 seconds
      when sec < 90 # a minute ago
        timeout = 45 * 1000 # 45 seconds
      when min < 45 # x minutes ago
        timeout = 60 * 1000 # 1 minute
      when min < 90 # an hour ago
        timeout = 45 * 60 * 1000 # 45 minutes
      when hr < 22 # x hours ago
        timeout = 60 * 60 * 1000 # 1 hour
      when hr < 36 # a day ago
        timeout = 14 * 60 * 60 * 1000 # 14 hours
      when day < 26 # x days ago
        timeout = 24 * 60 * 60 * 1000 # 1 day
      when day < 46 # a month ago
        timeout = 20 * 24 * 60 * 60 * 1000 # 20 days
      when day < 320 # x momnths ago
        timeout = 274 * 24 * 60 * 60 * 1000 # 274 days
      when day < 548 # a year ago
        timeout = 228 * 24 * 60 * 60 * 1000 # 228 days
      else # x years ago
        timeout = 357 * 24 * 60 * 60 * 1000 # 357 days

    @timestampTimeout = if timeout? then setTimeout(@updateTimestamp, timeout) else null
    @timestamp.textContent = @notification.moment.fromNow()
