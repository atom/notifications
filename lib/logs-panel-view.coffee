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

    # Add Container
    @container = document.createElement('div')
    @container.classList.add('notifications-logs')
    @container.classList.add('panel-body')
    @element.appendChild(@container)

  getElement: -> @element

  addNotification: (notificationElement) ->
    @container.appendChild(notificationElement)
