moment = require 'moment'

module.exports =
class StatusBarManager
  count: 0

  constructor: (statusBar, @duplicateTimeDelay) ->
    @render()
    @tile = statusBar.addRightTile(
      item: @element
      priority: 100
    )

  render: ->
    @number = document.createElement('div')
    @number.textContent = @count
    @number.addEventListener 'animationend', (e) => @number.classList.remove('new-notification') if e.animationName is 'new-notification'

    @element = document.createElement('a')
    @element.classList.add('notifications-count', 'inline-block')
    @tooltip = atom.tooltips.add(@element, title: 'Notifications')
    span = document.createElement('span')
    span.appendChild(@number)
    @element.appendChild(span)
    @element.addEventListener 'click', => atom.commands.dispatch(@element, 'notifications:toggle-log')

    lastNotification = null
    for notification in atom.notifications.getNotifications()
      if lastNotification?
        # do not show duplicates unless some amount of time has passed
        timeSpan = notification.getTimestamp() - lastNotification.getTimestamp()
        unless timeSpan < @duplicateTimeDelay and notification.isEqual(lastNotification)
          @addNotification(notification)
      else
        @addNotification(notification)

      lastNotification = notification

  destroy: ->
    @tile.destroy()
    @tile = null
    @tooltip.dispose()
    @tooltip = null

  addNotification: (notification) ->
    date = moment(notification.timestamp).format('LT')
    @tooltip.dispose()
    @tooltip = atom.tooltips.add(@element, title: "Last Notification #{date}")
    @element.setAttribute('last-type', notification.getType())
    @number.textContent = ++@count
    @number.classList.add('new-notification')

  clear: ->
    @count = 0
    @number.textContent = @count
    @element.removeAttribute 'last-type'
    @tooltip.dispose()
    @tooltip = atom.tooltips.add(@element, title: "Notifications")
