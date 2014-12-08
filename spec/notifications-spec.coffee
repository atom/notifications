NotificationElement = require '../lib/notification-element'
$ = require 'jquery'

describe "Notifications", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('notifications')

    waitsForPromise ->
      activationPromise

  describe "when the package is activated", ->
    it "attaches an atom-notifications element to the dom", ->
      expect(workspaceElement.querySelector('atom-notifications')).toBeDefined()

  describe "when notifications are added to atom.notifications", ->
    notificationContainer = null
    beforeEach ->
      notificationContainer = workspaceElement.querySelector('atom-notifications')
      spyOn($, 'ajax')

    it "adds an atom-notification element to the container with a class corresponding to the type", ->
      expect(notificationContainer.childNodes.length).toBe 0

      atom.notifications.addSuccess('A message')
      notification = notificationContainer.querySelector('atom-notification.success')
      expect(notificationContainer.childNodes.length).toBe 1
      expect(notification).toHaveClass 'success'
      expect(notification.querySelector('.message').textContent).toBe 'A message'

      atom.notifications.addInfo('A message')
      expect(notificationContainer.childNodes.length).toBe 2
      expect(notificationContainer.querySelector('atom-notification.info')).toBeDefined()

      atom.notifications.addWarning('A message')
      expect(notificationContainer.childNodes.length).toBe 3
      expect(notificationContainer.querySelector('atom-notification.warning')).toBeDefined()

      atom.notifications.addError('A message')
      expect(notificationContainer.childNodes.length).toBe 4
      expect(notificationContainer.querySelector('atom-notification.error')).toBeDefined()

      atom.notifications.addFatalError('A message')
      expect(notificationContainer.childNodes.length).toBe 5
      expect(notificationContainer.querySelector('atom-notification.fatal')).toBeDefined()

    describe "when a dismissable notification is added", ->
      it "is removed when Notification::dismiss() is called", ->
        notification = atom.notifications.addSuccess('A message', dismissable: true)
        notificationElement = notificationContainer.querySelector('atom-notification.success')

        expect(notificationContainer.childNodes.length).toBe 1

        notification.dismiss()

        advanceClock(NotificationElement::visibilityDuration)
        expect(notificationElement).toHaveClass 'remove'

        advanceClock(NotificationElement::animationDuration)
        expect(notificationContainer.childNodes.length).toBe 0

      it "is removed when the close icon is clicked", ->
        notification = atom.notifications.addSuccess('A message', dismissable: true)
        notificationElement = notificationContainer.querySelector('atom-notification.success')

        expect(notificationContainer.childNodes.length).toBe 1

        notificationElement.querySelector('.close.icon').click()

        advanceClock(NotificationElement::visibilityDuration)
        expect(notificationElement).toHaveClass 'remove'

        advanceClock(NotificationElement::animationDuration)
        expect(notificationContainer.childNodes.length).toBe 0

    describe "when an autoclose notification is added", ->
      it "closes and removes the message after a given amount of time", ->
        atom.notifications.addSuccess('A message')
        notification = notificationContainer.querySelector('atom-notification.success')
        expect(notification).not.toHaveClass 'remove'

        advanceClock(NotificationElement::visibilityDuration)
        expect(notification).toHaveClass 'remove'
        expect(notificationContainer.childNodes.length).toBe 1

        advanceClock(NotificationElement::animationDuration)
        expect(notificationContainer.childNodes.length).toBe 0

    describe "when an exception is thrown", ->
      describe "when the editor is in dev mode", ->
        beforeEach ->
          spyOn(atom, 'inDevMode').andReturn true
          try
            a + 1
          catch e
            window.onerror.call(window, e.toString(), 'abc', 2, 3, e)

        it "does not display a notification", ->
          notificationContainer = workspaceElement.querySelector('atom-notifications')
          fatalError = notificationContainer.querySelector('atom-notification.fatal')
          expect(notificationContainer.childNodes.length).toBe 0
          expect(fatalError).toBe null

      describe "when an exception is thrown from a package", ->
        beforeEach ->
          spyOn(atom, 'inDevMode').andReturn false
          try
            a + 1
          catch e
            window.onerror.call(window, e.toString(), 'abc', 2, 3, e)

        it "displays a fatal error with the package name in the error", ->
          notificationContainer = workspaceElement.querySelector('atom-notifications')
          fatalError = notificationContainer.querySelector('atom-notification.fatal')
          expect(notificationContainer.childNodes.length).toBe 1
          expect(fatalError).toHaveClass 'has-close'
          expect(fatalError.innerHTML).toContain 'ReferenceError: a is not defined'
          expect(fatalError.innerHTML).toContain "<a href=\"https://github.com/atom/notifications\">notifications package</a>"
          expect(fatalError.getPackageName()).toBe 'notifications'

          issueBody = fatalError.getIssueBody()
          expect(issueBody).toMatch /Atom Version\*\*: [0-9].[0-9]+.[0-9]+/ig
          expect(issueBody).not.toMatch /Unknown/ig
          expect(issueBody).toContain 'ReferenceError: a is not defined'
          expect(issueBody).toContain 'Thrown From**: [notifications](https://github.com/atom/notifications) package'

      describe "when an exception is thrown from core", ->
        beforeEach ->
          spyOn(atom, 'inDevMode').andReturn false
          try
            a + 1
          catch e
            stackLines = e.stack.split('\n')
            stackLines.splice(1, 1) # strip out the notifications reference
            e.stack = stackLines.join('\n')
            window.onerror.call(window, e.toString(), 'abc', 2, 3, e)

        it "displays a fatal error with the package name in the error", ->
          notificationContainer = workspaceElement.querySelector('atom-notifications')
          fatalError = notificationContainer.querySelector('atom-notification.fatal')
          expect(notificationContainer.childNodes.length).toBe 1
          expect(fatalError).toBeDefined()
          expect(fatalError).toHaveClass 'has-close'
          expect(fatalError.innerHTML).toContain 'ReferenceError: a is not defined'
          expect(fatalError.innerHTML).toContain 'bug in Atom'
          expect(fatalError.getPackageName()).toBeUndefined()

          issueBody = fatalError.getIssueBody()
          expect(issueBody).toContain 'ReferenceError: a is not defined'
          expect(issueBody).toContain 'Thrown From**: Atom Core'

      describe "when the error has not been reported", ->
        beforeEach ->
          spyOn(atom, 'inDevMode').andReturn false
          $.ajax.andCallFake (url, settings) -> settings.success(items: [])
          try
            a + 1
          catch e
            window.onerror.call(window, e.toString(), 'abc', 2, 3, e)

        it "asks the user to create an issue", ->
          fatalError = notificationContainer.querySelector('atom-notification.fatal')
          button = fatalError.querySelector('.btn')
          expect(button.textContent).toContain 'Create Issue'
          fatalNotification = fatalError.querySelector('.fatal-notification')
          expect(fatalNotification.textContent).toContain 'You can help by creating an issue'
          expect(button.getAttribute('href')).toContain '%23%23%23%20Steps%20To%20Reproduce'

      describe "when the error has been reported", ->
        beforeEach ->
          spyOn(atom, 'inDevMode').andReturn false
          $.ajax.andCallFake (url, settings) -> settings.success
            items: [
              {
                title: 'ReferenceError: a is not defined'
                html_url: 'http://url.com/ok'
              }
            ]
          try
            a + 1
          catch e
            window.onerror.call(window, e.toString(), 'abc', 2, 3, e)

        it "asks the user to create an issue", ->
          fatalError = notificationContainer.querySelector('atom-notification.fatal')
          button = fatalError.querySelector('.btn')
          expect(button.textContent).toContain 'View Issue'
          expect(button.getAttribute('href')).toBe 'http://url.com/ok'
          fatalNotification = fatalError.querySelector('.fatal-notification')
          expect(fatalNotification.textContent).toContain 'already been reported'
