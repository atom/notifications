{Emitter} = require 'atom'

module.exports = class LogsPanelView
  itemClickCallbacks: []

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
    @element.classList.add('logs')

    # Add Header
    header = document.createElement('header')
    header.classList.add('panel-heading')
    header.classList.add('padded')
    @element.appendChild(header)

    # Add Container
    @container = document.createElement('div')
    @container.classList.add('notifications-logs')
    @container.classList.add('panel-body')
    @element.appendChild(@container)

  destroy: ->
    @element.remove()

  getElement: -> @element

  getURI: -> 'atom://notifications/logs'

  getTitle: -> 'Log'

  getDefaultLocation: -> 'bottom'

  getAllowedLocations: -> ['left', 'right', 'bottom']

  toggle: -> atom.workspace.toggle(this)

  addNotification: (notification) ->
    element = atom.views.getView(notification).element.cloneNode(true)
    element.addEventListener('click', => @emitter.emit('item-clicked', notification))
    @container.appendChild(element)

  onItemClick: (callback) ->
    @emitter.on 'item-clicked', callback
