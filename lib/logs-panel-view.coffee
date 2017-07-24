# The logs panel
module.exports =
class LogsPanelView
  constructor: ->

    # Create root element
    @element = document.createElement('div')
    @element.classList.add('logs')

    # Add Header
    header = document.createElement('header')
    header.classList.add('panel-heading')
    header.classList.add('padded')
    header.textContent = "Logs"
    @element.appendChild(header)

    # Add Header
    closeButton = document.createElement('i')
    closeButton.classList.add('close-notification-logs')
    closeButton.classList.add('icon')
    closeButton.classList.add('icon-x')
    closeButton.addEventListener('click', -> atom.commands.dispatch(atom.views.getView(atom.workspace), 'notifications:toggle-logs'))
    header.appendChild(closeButton)

    # Add Container
    @container = document.createElement('div')
    @container.classList.add('notifications-logs')
    @container.classList.add('panel-body')
    @element.appendChild(@container)

  getElement: -> @element

  collapseAll: ->
    el.classList.add('collapse') for el in @element.querySelectorAll 'atom-notification'

  addNotification: (notification) ->
    canExpand = (notification.options.detail? or notification.options.description? or notification.options.buttons?)

    element = atom.views.getView(notification).element.cloneNode(true)
    element.classList.add('collapse')
    element.addEventListener('click', (e) =>
      shouldExpand = element.classList.contains('collapse') and canExpand
      @collapseAll()
      element.classList.remove('collapse') if shouldExpand
    )
    @container.appendChild(element)
