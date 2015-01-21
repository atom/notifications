fs = require 'fs'
path = require 'path'
async = require 'async'
marked = require 'marked'

NotificationIssue = require './notification-issue'

class NotificationElement extends HTMLElement
  animationDuration: 700
  visibilityDuration: 5000

  constructor: ->

  initialize: (@model) ->
    @issue = new NotificationIssue(@model) if @model.getType() is 'fatal'
    @generateMarkup()
    if @model.isDismissable()
      @model.onDidDismiss => @removeNotification()
    else
      @autohide()
    this

  getModel: -> @model

  generateMarkup: ->
    # OMG we need a view / data-binding framework
    @classList.add "#{@model.getType()}"
    @classList.add "icon", "icon-#{@model.getIcon()}", "native-key-bindings"

    @setAttribute('tabindex', '-1')

    notificationContent = document.createElement('div')
    notificationContent.classList.add('content')
    @appendChild(notificationContent)

    notificationContainer = document.createElement('div')
    notificationContainer.classList.add('item')
    notificationContainer.classList.add('message')
    notificationContainer.innerHTML = marked(@model.getMessage())
    notificationContent.appendChild(notificationContainer)

    if detail = @model.getDetail()
      addSplitLinesToContainer = (container, content) ->
        for line in content.split('\n')
          div = document.createElement('div')
          div.classList.add 'line'
          div.textContent = line
          container.appendChild(div)
        return

      @classList.add('has-detail')
      detailContainer = document.createElement('div')
      detailContainer.classList.add('item')
      detailContainer.classList.add('detail')
      addSplitLinesToContainer(detailContainer, detail)
      notificationContent.appendChild(detailContainer)

      if stack = @model.getOptions().stack
        stackToggle = document.createElement('a')
        stackContainer = document.createElement('div')

        stackToggle.setAttribute('href', '#')
        stackToggle.classList.add 'stack-toggle'
        stackToggle.addEventListener 'click', (e) => @handleStackTraceToggleClick(e, stackContainer)

        stackContainer.classList.add 'stack-container'
        addSplitLinesToContainer(stackContainer, stack)

        detailContainer.appendChild(stackToggle)
        detailContainer.appendChild(stackContainer)
        @handleStackTraceToggleClick({target: stackToggle}, stackContainer)

    if @model.type is 'fatal'
      fatalContainer = document.createElement('div')
      fatalContainer.classList.add('item')

      fatalNotification = document.createElement('div')
      fatalNotification.classList.add('fatal-notification')

      repoUrl = @issue.getRepoUrl()
      packageName = @issue.getPackageName()
      showCreateIssueButton = true
      if packageName? and repoUrl?
        fatalNotification.innerHTML = "The error was thrown from the <a href=\"#{repoUrl}\">#{packageName} package</a>"
      else if packageName?
        showCreateIssueButton = false
        fatalNotification.textContent = "The error was thrown from the #{packageName} package."
      else
        fatalNotification.textContent = 'This is likely a bug in Atom.'

      # We only show the create issue button if it's clearly in atom core or in a package with a repo url
      if showCreateIssueButton
        issueButton = document.createElement('a')
        issueButton.setAttribute('href', @issue.getIssueUrl())
        issueButton.classList.add('btn')
        issueButton.classList.add('btn-error')
        if packageName? and repoUrl?
          issueButton.textContent = "Create issue on the #{packageName} package"
        else
          issueButton.textContent = "Create issue on atom/atom"

        async.parallel
          issue: (callback) =>
            @issue.fetchIssue (issue) => callback(null, issue)
          shortUrl: (callback) =>
            @issue.getShortUrl (url) -> callback(null, url)
        , (err, result) ->
          if result.issue?
            issueButton.setAttribute('href', result.issue.html_url)
            issueButton.textContent = "View Issue"
            fatalNotification.textContent += " This issue has already been reported."
          else
            issueButton.setAttribute('href', result.shortUrl) if result.shortUrl?
            fatalNotification.textContent += " You can help by creating an issue. Please explain what actions triggered this error."

        toolbar = document.createElement('div')
        toolbar.classList.add('btn-toolbar')
        toolbar.appendChild(issueButton)

        fatalContainer.appendChild(fatalNotification)
        fatalContainer.appendChild(toolbar)
        notificationContent.appendChild(fatalContainer)

    if @model.isDismissable()
      @classList.add('has-close')
      closeButton = document.createElement('button')
      closeButton.classList.add('close', 'icon', 'icon-x')
      closeButton.addEventListener 'click', => @handleRemoveNotificationClick()
      @appendChild(closeButton)

      closeAllButton = document.createElement('button')
      closeAllButton.textContent = 'Close All'
      closeAllButton.classList.add('close-all', 'btn', @getButtonClass())
      closeAllButton.addEventListener 'click', => @handleRemoveAllNotificationsClick()
      @appendChild(closeAllButton)

  removeNotification: ->
    @classList.add('remove')
    @removeNotificationAfterTimeout()

  handleRemoveNotificationClick: ->
    @model.dismiss()

  handleRemoveAllNotificationsClick: ->
    notifications = atom.notifications.getNotifications()
    for notification in notifications
      if notification.isDismissable() and not notification.isDismissed()
        notification.dismiss()
    return

  handleStackTraceToggleClick: (e, container) ->
    e.preventDefault?()
    if container.style.display is 'none'
      e.target.innerHTML = '<span class="icon icon-dash"></span>Hide Stack Trace'
      container.style.display = 'block'
    else
      e.target.innerHTML = '<span class="icon icon-plus"></span>Show Stack Trace'
      container.style.display = 'none'

  autohide: ->
    setTimeout =>
      @classList.add('remove')
      @removeNotificationAfterTimeout()
    , @visibilityDuration

  removeNotificationAfterTimeout: ->
    setTimeout =>
      @remove()
    , @animationDuration # keep in sync with CSS animation

  getButtonClass: ->
    type = "btn-#{@model.getType()}"
    if type == 'btn-fatal' then 'btn-error' else type

module.exports = NotificationElement = document.registerElement 'atom-notification', prototype: NotificationElement.prototype
