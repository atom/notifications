
const {Notification} = require('atom');
const {generateFakeFetchResponses, generateException} = require('./helper');

describe("Notifications Count", () => {
  let [workspaceElement, statusBarManager, notificationsCountContainer] = Array.from([]);

  beforeEach(() => {
    workspaceElement = atom.views.getView(atom.workspace);
    atom.notifications.clear();

    waitsForPromise(() =>
      Promise.all([
        atom.packages.activatePackage('notifications'),
        atom.packages.activatePackage('status-bar')
      ]));

    runs(() => {
      statusBarManager = atom.packages.getActivePackage('notifications').mainModule.statusBarManager;
      notificationsCountContainer = workspaceElement.querySelector('.notifications-count');
    });
  });

  describe("when the package is activated", () =>
    it("attaches an .notifications-count element to the dom", () => {
      expect(statusBarManager.count).toBe(0);
      expect(notificationsCountContainer).toExist();
    })
  );

  describe("when there are notifications before activation", () => {
    beforeEach(() =>
      waitsForPromise(() =>
        // Wrapped in Promise.resolve so this test continues to work on earlier versions of Atom
        Promise.resolve(atom.packages.deactivatePackage('notifications'))
      )
    );

    it("displays counts notifications", () => {
      let warning = new Notification('warning', 'Un-displayed warning');
      let error = new Notification('error', 'Displayed error');
      error.setDisplayed(true);

      atom.notifications.addNotification(error);
      atom.notifications.addNotification(warning);

      waitsForPromise(() => atom.packages.activatePackage('notifications'));

      runs(() => {
        statusBarManager = atom.packages.getActivePackage('notifications').mainModule.statusBarManager;
        notificationsCountContainer = workspaceElement.querySelector('.notifications-count');
        expect(statusBarManager.count).toBe(2);
        expect(parseInt(notificationsCountContainer.textContent, 10)).toBe(2);
      });
    });
  });

  describe("when notifications are added to atom.notifications", () => {
    beforeEach(() => generateFakeFetchResponses());

    it("will add the new-notification class for as long as the animation", () => {
      let notificationsCountNumber = notificationsCountContainer.firstChild.firstChild;
      expect(notificationsCountNumber).not.toHaveClass('new-notification');
      atom.notifications.addInfo('A message');
      expect(notificationsCountNumber).toHaveClass('new-notification');

      let animationend = new AnimationEvent('animationend', {animationName: 'new-notification'});
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
