{Emitter} = require 'atom'

typeIcons =
  fatal: 'bug'
  error: 'flame'
  warning: 'alert'
  info: 'info'
  success: 'check'

module.exports = class NotificationsLog
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
    header = document.createElement('header')
    @element.appendChild(header)

    # Add Container
    @list = document.createElement('ul')
    @element.appendChild(@list)

    # Add Buttons
    for type, icon of typeIcons
      button = document.createElement('button')
      button.classList.add('notification-type', 'btn', 'icon', "icon-#{icon}", 'show-type', type)
      button.dataset.type = type
      button.addEventListener 'click', (e) => @toggleType(e.target.dataset.type)
      atom.tooltips.add(button, {title: "Toggle #{type} notifications"})
      header.appendChild(button)

    # Add Notifications
    for notification in atom.notifications.getNotifications()
      @addNotification(notification)

  destroy: ->
    @element.remove()
    @emitter.emit 'did-destroy'

  getElement: -> @element

  getURI: -> 'atom://notifications/log'

  getTitle: -> 'Log'

  getLongTitle: -> 'Notifications Log'

  getDefaultLocation: -> 'bottom'

  getAllowedLocations: -> ['left', 'right', 'bottom']

  toggle: -> atom.workspace.toggle(this)

  toggleType: (type, force) ->
    button = @element.querySelector(".notification-type.#{type}")
    hide = not button.classList.toggle('show-type', force)
    @list.classList.toggle("hide-#{type}", hide)

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

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  getIconName: -> 'comment'
