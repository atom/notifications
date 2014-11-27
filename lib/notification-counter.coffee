# Notification counter in the status bar

{View} = require 'atom'

module.exports =
class NotificationCounterView extends View
  @content: ->
    @div class: 'notification-counter inline-block', =>
      @span outlet: 'icon', class: 'icon'
      @output outlet: 'labelError', class: 'item is-error'
      @output outlet: 'labelWarning', class: 'item is-warning'

  initialize: (statusBar) ->
    @labelError.text('1')
    @labelError.setTooltip("1 error")
    @labelWarning.text('3')
    @labelWarning.setTooltip("3 warnings")
    statusBar.prependLeft(this)

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
