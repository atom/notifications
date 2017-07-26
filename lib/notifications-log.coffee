{Emitter} = require 'atom'

module.exports = class NotificationsLog
  typesShown:
    fatal: true
    error: true
    warning: true
    info: true
    success: true

  constructor: ->
    @render()
    @emitter = new Emitter
    atom.workspace.open(this, {
      activatePane: false
      activateItem: false
      searchAllPanes: true
    })

  render: ->

    # Create root element
    @element = document.createElement('div')
    @element.classList.add('notifications-log')

    # Add Header
    @header = document.createElement('header')
    @element.appendChild(@header)

    # Add Container
    @list = document.createElement('ul')
    @element.appendChild(@list)

    # Add Buttons
    for type, shown of @typesShown

      icon = switch type
        when 'fatal' then 'bug'
        when 'error' then 'flame'
        when 'warning' then 'alert'
        when 'info' then 'info'
        when 'success' then 'check'

      @list.classList.toggle("hide-#{type}", not shown)

      button = document.createElement('button')
      button.classList.add('notification-type', 'btn', 'icon', "icon-#{icon}", type)
      button.classList.toggle('show-type', shown)
      button.dataset.type = type
      button.addEventListener 'click', (e) => @toggleType(e.target.dataset.type)
      atom.tooltips.add(button, {title: "Toggle #{type} notifications"})
      @header.appendChild(button)

    # Add Notifications
    for notification in atom.notifications.getNotifications()
      @addNotification(notification)

  destroy: ->
    @element.remove()

  getElement: -> @element

  getURI: -> 'atom://notifications/log'

  getTitle: -> 'Log'

  getDefaultLocation: -> 'bottom'

  getAllowedLocations: -> ['left', 'right', 'bottom']

  toggle: -> atom.workspace.toggle(this)

  toggleType: (type) ->
    show = not @typesShown[type]
    @typesShown[type] = show
    button = @header.querySelector(".notification-type.#{type}")
    @list.classList.toggle("hide-#{type}", not show)
    button.classList.toggle('show-type', show)

  addNotification: (notification) ->
    # TODO: should probably create new element instead of cloning
    atomNotification = atom.views.getView(notification).element.cloneNode(true)

    item = document.createElement('li')
    item.classList.add(notification.getType())
    item.appendChild(atomNotification)
    item.addEventListener('click', => @emitter.emit('item-clicked', notification))
    @list.appendChild(item)

  onItemClick: (callback) ->
    @emitter.on 'item-clicked', callback
