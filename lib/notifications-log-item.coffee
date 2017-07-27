{Emitter} = require 'atom'

module.exports = class NotificationsLogItem
  timestampTimeout: null

  constructor: (@notification) ->
    @emitter = new Emitter
    @updateTimestamp = @updateTimestamp.bind(this)
    @render()

  render: ->
    # TODO: should probably create new element instead of cloning
    notificationView = atom.views.getView(@notification)
    notificationElement = @renderNotification(notificationView)

    if @notification.getType() is 'fatal'
      notificationView.getRenderPromise().then =>
        @element.replaceChild(@renderNotification(notificationView), notificationElement)

    @timestamp = document.createElement('div')
    @timestamp.classList.add('timestamp')
    atom.tooltips.add(@timestamp, title: @notification.timestamp.toLocaleString())
    @updateTimestamp()

    @element = document.createElement('li')
    @element.classList.add('notifications-log-item', @notification.getType())
    @element.appendChild(notificationElement)
    @element.appendChild(@timestamp)
    @element.addEventListener('click', => @emitter.emit 'click')

  renderNotification: (view) ->
    view.element.cloneNode(true)

  getElement: -> @element

  destroy: ->
    @element.remove()
    clearTimeout @timestampTimeout
    @emitter.emit 'did-destroy'

  onClick: (callback) ->
    @emitter.on 'click', callback

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  updateTimestamp: ->
    # modified from https://github.com/github/time-elements/blob/master/src/relative-time.js#L53
    ms = new Date().getTime() - @notification.timestamp.getTime()
    sec = Math.round(ms / 1000)
    min = Math.round(sec / 60)
    hr = Math.round(min / 60)
    day = Math.round(hr / 24)
    month = Math.round(day / 30)
    year = Math.round(month / 12)

    switch
      when ms < 0
        timeout = 1000 # 1 second
        text = 'From the future'
      when sec < 10
        timeout = 10 * 1000 # 10 seconds
        text = 'Just now'
      when sec < 45
        timeout = 1000 # 1 second
        text = "#{sec} seconds ago"
      when sec < 90
        timeout = 45 * 1000 # 45 seconds
        text = 'A minute ago'
      when min < 45
        timeout = 60 * 1000 # 1 minute
        text = "#{min} minutes ago"
      when min < 90
        timeout = 45 * 60 * 1000 # 45 minutes
        text = 'An hour ago'
      when hr < 24
        timeout = 60 * 60 * 1000 # 1 hour
        text = "#{hr} hours ago"
      when hr < 36
        timeout = 12 * 60 * 60 * 1000 # 12 hours
        text = 'A day ago'
      else
        timeout = null # after this point it doesn't matter
        text = 'A long time ago'
      # when day < 30
      #   timeout = 24 * 60 * 60 * 1000 # 1 day
      #   text = "#{day} days ago"
      # when day < 45
      #   timeout = 15 * 24 * 60 * 60 * 1000 # 15 days
      #   text = 'A month ago'
      # when month < 12
      #   timeout = 30 * 24 * 60 * 60 * 1000 # 1 month
      #   text = "#{month} months ago"
      # when month < 18
      #   timeout = 6 * 30 * 24 * 60 * 60 * 1000 # 6 months
      #   text = 'A year ago'
      # else
      #   timeout = 12 * 30 * 24 * 60 * 60 * 1000 # 1 year
      #   text = "#{year} years ago"

    @timestampTimeout = if timeout? then setTimeout(@updateTimestamp, timeout) else null
    @timestamp.textContent = text
