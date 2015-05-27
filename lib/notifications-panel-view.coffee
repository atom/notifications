# The panel with the buttons
# TODO: remove this
module.exports =
class NotificationsPanelView
  constructor: ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('notifications')
    @element.classList.add('padded')

    toolbar = document.createElement('div')
    toolbar.classList.add('btn-toolbar')
    @element.appendChild(toolbar)

    fatalErrorButton = document.createElement('button')
    fatalErrorButton.classList.add('btn')
    fatalErrorButton.textContent = "Create Fatal Error"
    fatalErrorButton.addEventListener 'click', @createFatalError
    toolbar.appendChild(fatalErrorButton)

    errorButton = document.createElement('button')
    errorButton.classList.add('btn')
    errorButton.textContent = "Create Error"
    errorButton.addEventListener 'click', @createError
    toolbar.appendChild(errorButton)

    warningButton = document.createElement('button')
    warningButton.classList.add('btn')
    warningButton.textContent = "Create Warning"
    warningButton.addEventListener 'click', @createWarning
    toolbar.appendChild(warningButton)

    infoButton = document.createElement('button')
    infoButton.classList.add('btn')
    infoButton.textContent = "Create Info Notification"
    infoButton.addEventListener 'click', @createInfo
    toolbar.appendChild(infoButton)

    successButton = document.createElement('button')
    successButton.classList.add('btn')
    successButton.textContent = "Create Success Notification"
    successButton.addEventListener 'click', @createSuccess
    toolbar.appendChild(successButton)

  getElement: -> @element

  createFatalError: ->
    atom.commands.dispatch(atom.views.getView(atom.workspace), 'notifications:trigger-error')

  createError: ->
    message = 'Failed to load your user config'
    options =
      dismissable: true
      detail: """
        line 6: unexpected newline
        'metrics'::
        ^
      """
    atom.notifications.addError(message, options)

  createWarning: ->
    atom.notifications.addWarning('Oops warning')

  createInfo: ->
    atom.notifications.addInfo('Some info for you', icon: 'comment')

  createSuccess: ->
    atom.notifications.addSuccess('Yeah, success!')
