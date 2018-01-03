
const {Notification} = require('atom');
const {generateFakeFetchResponses} = require('./helper-v2');

describe("Notifications Count", () => {
  let [workspaceElement, notificationsStatusView, notificationsCountContainer] = Array.from([]);

  beforeEach(async () => {
    workspaceElement = atom.views.getView(atom.workspace);
    atom.notifications.clear();

    await Promise.all([
      atom.packages.activatePackage('notifications'),
      atom.packages.activatePackage('status-bar')
    ]);

    notificationsStatusView = atom.packages.getActivePackage('notifications').mainModule.notificationsStatusView;
    notificationsCountContainer = workspaceElement.querySelector('.notifications-count');
  });

  describe("when the package is activated", () =>
    it("attaches an .notifications-count element to the dom", () => {
      expect(notificationsStatusView.count).toBe(0);
      expect(notificationsCountContainer).toExist();
    })
  );

  describe("when there are notifications before activation", () => {
    beforeEach(async () => {
      await atom.packages.deactivatePackage('notifications');
    });

    it("displays counts notifications", async () => {
      let warning = new Notification('warning', 'Un-displayed warning');
      let error = new Notification('error', 'Displayed error');
      error.setDisplayed(true);

      atom.notifications.addNotification(error);
      atom.notifications.addNotification(warning);

      await atom.packages.activatePackage('notifications');

      notificationsStatusView = atom.packages.getActivePackage('notifications').mainModule.notificationsStatusView;
      notificationsCountContainer = workspaceElement.querySelector('.notifications-count');
      expect(notificationsStatusView.count).toBe(2);
      expect(parseInt(notificationsCountContainer.textContent, 10)).toBe(2);
    });
  });

  describe("when notifications are added to atom.notifications", () => {
    beforeEach(() => generateFakeFetchResponses());

    it("will add the new-notification class for as long as the animation", () => {
      let notificationsCountNumber = notificationsCountContainer.firstChild.firstChild;
      let animationend = new AnimationEvent('animationend', {animationName: 'new-notification'});
      notificationsCountNumber.dispatchEvent(animationend);
      expect(notificationsCountNumber).not.toHaveClass('new-notification');
      atom.notifications.addInfo('A message');
      expect(notificationsCountNumber).toHaveClass('new-notification');

      notificationsCountNumber.dispatchEvent(animationend);
      expect(notificationsCountNumber).not.toHaveClass('new-notification');
    });

    it("changes the .notifications-count element last-type attribute corresponding to the type", () => {
      atom.notifications.addSuccess('A message');
      expect(notificationsCountContainer.getAttribute('last-type')).toBe('success');

      atom.notifications.addInfo('A message');
      expect(notificationsCountContainer.getAttribute('last-type')).toBe('info');

      atom.notifications.addWarning('A message');
      expect(notificationsCountContainer.getAttribute('last-type')).toBe('warning');

      atom.notifications.addError('A message');
      expect(notificationsCountContainer.getAttribute('last-type')).toBe('error');

      atom.notifications.addFatalError('A message');
      expect(notificationsCountContainer.getAttribute('last-type')).toBe('fatal');
    });
  });

  describe("when the element is clicked", () => {
    beforeEach(() => {
      spyOn(atom.commands, "dispatch");
      notificationsCountContainer.click();
    });

    it("will dispatch notifications:toggle-log", () => {
      expect(atom.commands.dispatch).toHaveBeenCalledWith(notificationsCountContainer, "notifications:toggle-log");
    });
  });
});
