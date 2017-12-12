const { CompositeDisposable, Disposable } = require('atom');
const moment = require('moment');

module.exports = class NotificationsStatusView {

    constructor(statusBar, duplicateTimeDelay) {
      this.count = 0;
      this.duplicateTimeDelay = duplicateTimeDelay;
      this.subscriptions = new CompositeDisposable;
      this.render();
      this.tile = statusBar.addRightTile({
        item: this.element,
        priority: 100
      });
      this.subscriptions.add(new Disposable(() => { this.tile.destroy(); }));
      // TODO: uncomment next line when atom/atom#16074 is released
      // this.subscriptions.add(atom.notifications.onDidClearNotifications(() => this.clear()));
    }

    render() {
      this.number = document.createElement('div');
      this.number.textContent = this.count;
      this.number.addEventListener('animationend', (e) => {
        if (e.animationName === 'new-notification') {
          this.number.classList.remove('new-notification');
        }
      });

      this.element = document.createElement('a');
      this.element.classList.add('notifications-count', 'inline-block');
      this.tooltip = atom.tooltips.add(this.element, {title: 'Notifications'});
      let span = document.createElement('span');
      span.appendChild(this.number);
      this.element.appendChild(span);
      this.element.addEventListener('click', () => {
        atom.commands.dispatch(this.element, 'notifications:toggle-log')
      });

      let lastNotification = null;
      for (let notification of atom.notifications.getNotifications()) {
        if (lastNotification !== null) {
          // do not show duplicates unless some amount of time has passed
          let timeSpan = notification.getTimestamp() - lastNotification.getTimestamp();
          if (timeSpan > this.duplicateTimeDelay || !notification.isEqual(lastNotification)) {
            this.addNotification(notification);
          }
        } else {
          this.addNotification(notification);
        }

        lastNotification = notification;
      }
    }

    destroy() {
      this.subscriptions.dispose();
      this.tooltip.dispose();
    }

    addNotification(notification) {
      let date = moment(notification.timestamp).format('LT');
      this.tooltip.dispose();
      this.tooltip = atom.tooltips.add(this.element, {title: `Last Notification ${date}`});
      this.element.setAttribute('last-type', notification.getType());
      this.number.textContent = ++this.count;
      this.number.classList.add('new-notification');
    }

    clear() {
      this.count = 0;
      this.number.textContent = this.count;
      this.element.removeAttribute('last-type');
      this.tooltip.dispose();
      this.tooltip = atom.tooltips.add(this.element, {title: "Notifications"});
    }
  };
