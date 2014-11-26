# Notification counter in the status bar

{View} = require 'atom'

module.exports =
class NotificationCounterView extends View
  @content: ->
    @div class: 'notification-counter inline-block', =>
      @span class: 'icon icon-check is-success'
      @output outlet: 'labelError', class: 'item is-error'
      @output outlet: 'labelWarning', class: 'item is-warning'

  initialize: (statusBar) ->
    @labelError.text('1')
    @labelWarning.text('3')
    @setTooltip("1 error and 3 warnings")
    statusBar.prependLeft(this)
