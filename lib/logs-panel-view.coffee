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
    container = document.createElement('atom-logs')
    container.classList.add('panel-body')
    @element.appendChild(container)

    # Add some sample markup
    container.innerHTML = """
      <atom-log class="success icon icon-check native-key-bindings" tabindex="-1">
        <div class="content">
          <div class="message item">
            <p>Yeah, success!</p>
          </div>
        </div>
      </atom-log>

      <atom-log class="info icon icon-comment native-key-bindings" tabindex="-1">
        <div class="content">
          <div class="message item">
            <p>Some info for you</p>
          </div>
        </div>
      </atom-log>

      <atom-log class="warning icon icon-alert native-key-bindings" tabindex="-1">
        <div class="content">
          <div class="message item">
            <p>Oops warning</p>
          </div>
        </div>
      </atom-log>

      <atom-log class="error icon icon-flame native-key-bindings has-detail has-close" tabindex="-1">
        <div class="content">
          <div class="message item">
            <p>Failed to load your user config</p>
          </div>
          <div class="detail item">
            <div class="detail-content">
              <div class="line">line 6: unexpected newline</div>
              <div class="line">'metrics'::</div>
              <div class="line">^</div>
            </div>
          </div>
        </div>
      </atom-log>

      <atom-log class="fatal icon icon-bug native-key-bindings has-detail has-close has-stack" tabindex="-1">
        <div class="content">
          <div class="message item">
            <p>Uncaught ReferenceError: abc is not defined</p>
          </div>
          <div class="detail item">
            <div class="detail-content"><div class="line">  at atom-workspace.&lt;anonymous&gt; (/Users/simBook/Sir/atom/notifications/lib/main.coffee:114:7)</div></div>
            <a href="#" class="stack-toggle"><span class="icon icon-plus"></span>Show Stack Trace</a>
            <div class="stack-container" style="display: none;"><div class="line">ReferenceError: abc is not defined</div><div class="line">  at atom-workspace.&lt;anonymous&gt; (/Users/simBook/Sir/atom/notifications/lib/main.coffee:114:7)</div><div class="line">  at CommandRegistry.module.exports.CommandRegistry.handleCommandEvent (/Users/simBook/github/atom/src/command-registry.coffee:225:27)</div><div class="line">  at CommandRegistry.__bind [as handleCommandEvent] (/Users/simBook/github/atom/src/command-registry.coffee:1:1)</div><div class="line">  at CommandRegistry.module.exports.CommandRegistry.dispatch (/Users/simBook/github/atom/src/command-registry.coffee:173:6)</div><div class="line">  at NotificationsPanelView.module.exports.NotificationsPanelView.createFatalError (/Users/simBook/Sir/atom/notifications/lib/notifications-panel-view.coffee:48:19)</div><div class="line">  at HTMLButtonElement.__bind (/Users/simBook/Sir/atom/notifications/lib/notifications-panel-view.coffee:3:1)</div><div class="line"></div></div>
          </div>
          <div class="meta item">
            <div class="fatal-notification">The error was thrown from the <a href="https://github.com/atom/notifications">notifications package</a>.  This issue has already been reported.</div>
            <div class="btn-toolbar">
              <a href="https://github.com/atom/notifications/issues/30" class="btn-issue btn btn-error">View Issue</a>
              <a href="#" class="btn-copy-report icon icon-clippy" title="" data-original-title="Copy error report to clipboard"></a>
            </div>
          </div>
        </div>
      </atom-log>
    """

  getElement: -> @element
