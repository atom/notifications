MessageElement = require './message-element'

module.exports =
class Message
  constructor: (@type, @message, @options={}) ->

  getIcon: ->
    return @options.icon if @options.icon?
    switch @type
      when 'fatal' then 'flame'
      when 'error' then 'x'
      when 'warning' then 'alert'
      when 'info' then 'info'
      when 'success' then 'check'

  getIssueUrl: ->
    "https://github.com/atom/atom/issues/new?title=#{encodeURI(@getIssueTitle())}&body=#{encodeURI(@getIssueBody())}"

  getIssueTitle: ->
    @message

  getIssueBody: ->
    """
    #{@options.errorDetail}

    Stack Trace
    ```
    #{@options.stack}
    ```
    """

atom.views.addViewProvider
  modelConstructor: Message
  viewConstructor: MessageElement
