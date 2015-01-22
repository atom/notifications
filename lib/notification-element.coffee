fs = require 'fs'
path = require 'path'
marked = require 'marked'

NotificationIssue = require './notification-issue'
TemplateHelper = require './template-helper'
UserUtilities = require './user-utilities'

NotificationTemplate = """
  <div class="content">
    <div class="message item"></div>
    <div class="detail item">
      <div class="detail-content"></div>
      <a href="#" class="stack-toggle"></a>
      <div class="stack-container"></div>
    </div>
    <div class="meta item"></div>
  </div>
  <div class="close icon icon-x"></div>
  <div class="close-all btn btn-error">Close All</div>
"""

FatalMetaNotificationTemplate = """
  <div class="fatal-notification"></div>
  <div class="btn-toolbar">
    <a href="#" class="btn btn-error"></a>
  </div>
"""

class NotificationElement extends HTMLElement
  animationDuration: 700
  visibilityDuration: 5000
  fatalTemplate: TemplateHelper.create(FatalMetaNotificationTemplate)

  constructor: ->

  initialize: (@model) ->
    @issue = new NotificationIssue(@model) if @model.getType() is 'fatal'
    @render()
    if @model.isDismissable()
      @model.onDidDismiss => @removeNotification()
    else
      @autohide()
    this

  getModel: -> @model

  render: ->
    @classList.add "#{@model.getType()}"
    @classList.add "icon", "icon-#{@model.getIcon()}", "native-key-bindings"

    @classList.add('has-detail') if detail = @model.getDetail()
    @classList.add('has-close') if @model.isDismissable()
    @classList.add('has-stack') if @model.getOptions().stack?

    @setAttribute('tabindex', '-1')

    @innerHTML = NotificationTemplate

    notificationContainer = @querySelector('.message')
    notificationContainer.innerHTML = marked(@model.getMessage())

    if detail = @model.getDetail()
      addSplitLinesToContainer(@querySelector('.detail-content'), detail)

      if stack = @model.getOptions().stack
        stackToggle = @querySelector('.stack-toggle')
        stackContainer = @querySelector('.stack-container')

        addSplitLinesToContainer(stackContainer, stack)

        stackToggle.addEventListener 'click', (e) => @handleStackTraceToggleClick(e, stackContainer)
        @handleStackTraceToggleClick({target: stackToggle}, stackContainer)

    if @model.isDismissable()
      closeButton = @querySelector('.close')
      closeButton.addEventListener 'click', => @handleRemoveNotificationClick()

      closeAllButton = @querySelector('.close-all')
      closeAllButton.classList.add @getButtonClass()
      closeAllButton.addEventListener 'click', => @handleRemoveAllNotificationsClick()

    @renderFatalError() if @model.getType() is 'fatal'

  renderFatalError: ->
    repoUrl = @issue.getRepoUrl()
    packageName = @issue.getPackageName()

    fatalContainer = @querySelector('.meta')
    fatalContainer.appendChild(TemplateHelper.render(@fatalTemplate))
    fatalNotification = @querySelector('.fatal-notification')

    issueButton = fatalContainer.querySelector('.btn')

    if packageName? and repoUrl?
      fatalNotification.innerHTML = "The error was thrown from the <a href=\"#{repoUrl}\">#{packageName} package</a>. "
    else if packageName?
      issueButton.remove()
      fatalNotification.textContent = "The error was thrown from the #{packageName} package. "
    else
      fatalNotification.textContent = "This is likely a bug in Atom. "

    # We only show the create issue button if it's clearly in atom core or in a package with a repo url
    if issueButton.parentNode?
      issueButton.setAttribute('href', @issue.getIssueUrl())
      if packageName? and repoUrl?
        issueButton.textContent = "Create issue on the #{packageName} package"
      else
        issueButton.textContent = "Create issue on atom/atom"

      promises = []
      promises.push @issue.findSimilarIssue()
      promises.push @issue.getIssueUrlForSystem()
      promises.push UserUtilities.checkPackageUpToDate(packageName) if packageName?

      Promise.all(promises).then (allData) ->
        [issue, newIssueUrl, packageCheck] = allData

        if issue?
          issueButton.setAttribute('href', issue.html_url)
          issueButton.textContent = "View Issue"
          fatalNotification.textContent += " This issue has already been reported."
        else if packageCheck? and !packageCheck.upToDate and !packageCheck.isCore
          issueButton.setAttribute('href', '#')
          issueButton.textContent = "Check for package updates"
          issueButton.addEventListener 'click', (e) ->
            e.preventDefault()
            command = 'settings-view:check-for-package-updates'
            atom.commands.dispatch(atom.views.getView(atom.workspace), command)

          fatalNotification.textContent += """
            #{packageName} is out of date: #{packageCheck.installedVersion} installed;
            #{packageCheck.latestVersion} latest.
            Upgrading to the latest version may fix this issue.
          """
        else
          issueButton.setAttribute('href', newIssueUrl) if newIssueUrl?
          fatalNotification.textContent += " You can help by creating an issue. Please explain what actions triggered this error."
      .catch (e) ->
        console.error e.message
        console.error e.stack

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

addSplitLinesToContainer = (container, content) ->
  for line in content.split('\n')
    div = document.createElement('div')
    div.classList.add 'line'
    div.textContent = line
    container.appendChild(div)
  return

module.exports = NotificationElement = document.registerElement 'atom-notification', prototype: NotificationElement.prototype
