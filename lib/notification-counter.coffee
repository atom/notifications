# Notification counter in the status bar

{View} = require 'atom'

module.exports =
class NotificationCounterView extends View

  warningCount: 0
  errorCount: 0

  @content: ->
    @div class: 'notification-counter inline-block', =>
      @span outlet: 'icon', class: 'icon'
      @output outlet: 'labelError', class: 'item is-error is-hidden'
      @output outlet: 'labelWarning', class: 'item is-warning is-hidden'

  initialize: (statusBar) ->
    @labelWarning.text(@warningCount)
    @labelWarning.setTooltip("warnings")
    @labelError.text(@errorCount)
    @labelError.setTooltip("errors")
    statusBar.prependLeft(this)

  increaseCounter: (type) ->
    switch type
      when 'warning'
        @warningCount++
        @labelWarning.text(@warningCount)
      when 'error'
        @errorCount++
        @labelError.text(@errorCount)
      when 'fatal'
        @errorCount++
        @labelError.text(@errorCount)

    if @warningCount > 0 then @labelWarning.removeClass('is-hidden')
    if @errorCount > 0 then @labelError.removeClass('is-hidden')

  setStatusIcon: (status) ->
    @icon.removeClass('is-progress  is-info       is-success  is-warning  is-error    is-fatal')
    @icon.removeClass('icon-sync    icon-comment  icon-check  icon-alert  icon-flame  icon-bug')
    @icon.addClass("is-#{status}") if status
    switch status
      when 'progress'
        @icon.addClass("icon-sync") if status
      when 'info'
        @icon.addClass("icon-comment") if status
      when 'success'
        @icon.addClass("icon-check") if status
      when 'warning'
        @icon.addClass("icon-alert") if status
      when 'error'
        @icon.addClass("icon-flame") if status
      when 'fatal'
        @icon.addClass("icon-bug") if status
