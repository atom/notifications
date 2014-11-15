# The panel with the buttons

Message = require './message'
MessageElement = require './message-element'

module.exports =
class MessagesPanelView
  constructor: ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('messages')
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
    infoButton.textContent = "Create Info Message"
    infoButton.addEventListener 'click', @createInfo
    toolbar.appendChild(infoButton)

    successButton = document.createElement('button')
    successButton.classList.add('btn')
    successButton.textContent = "Create Success Message"
    successButton.addEventListener 'click', @createSuccess
    toolbar.appendChild(successButton)

  getElement: -> @element

  createFatalError: =>
    atom.messages.add new Message('fatal', 'This is a fatal error')

  createError: =>
    message = 'Failed to load your user config'
    detail = """
      line 6: unexpected newline
      'metrics'::
      ^
    """
    atom.messages.add new Message('error', message, detail)

  createWarning: =>
    atom.messages.add new Message('warning', 'Oops warning')

  createInfo: =>
    atom.messages.add new Message('info', 'Some info for you')

  createSuccess: =>
    atom.messages.add new Message('success', 'Yeah, success!')
