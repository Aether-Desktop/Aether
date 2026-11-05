pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Single notification daemon for the whole session.
// Owns the D-Bus notification server so the bar, popup layer and dashboard all
// observe the same state instead of racing to create their own server.
QtObject {
    id: root

    property int _nextKey: 1
    property var popups: []

    readonly property var history: root.server.trackedNotifications
        ? root.server.trackedNotifications.values : []
    readonly property int count: root.history.length
    readonly property bool dnd: Config.dnd

    signal arrived(var notification)

    function handle(notification) {
        // Keep every notification for history, even while Do Not Disturb is on.
        notification.tracked = true;
        Qt.callLater(root.trimHistory);
        if (root.dnd) return;
        const key = root._nextKey++;
        let list = root.popups.slice();
        if (Config.notifications.grouping === true) {
            const filtered = [];
            for (let i = 0; i < list.length; i++)
                if (list[i].n.appName !== notification.appName) filtered.push(list[i]);
            list = filtered;
        }
        list.push({ key: key, n: notification });
        root.popups = list.slice(-4);
        root.arrived(notification);
    }

    function trimHistory() {
        const max = Math.max(10, Config.notifications.historySize || 100);
        const list = root.history.slice();
        if (list.length <= max) return;
        const remove = list.length - max;
        for (let i = 0; i < remove; i++) list[i].dismiss();
    }

    function removePopup(key) {
        const list = [];
        for (let i = 0; i < root.popups.length; i++)
            if (root.popups[i].key !== key) list.push(root.popups[i]);
        root.popups = list;
    }

    function dismissAll() {
        const list = root.history.slice();
        for (let i = 0; i < list.length; i++) list[i].dismiss();
        root.popups = [];
    }

    function dismiss(notification) {
        if (notification) notification.dismiss();
    }

    function invoke(action) {
        if (action) action.invoke();
    }

    function setDnd(enabled) {
        Config.set("notifications.doNotDisturb", enabled === true);
        if (enabled) root.popups = [];
    }

    property NotificationServer server: NotificationServer {
        id: notificationServer
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        actionsSupported: true
        actionIconsSupported: true
        persistenceSupported: true
        onNotification: (notification) => root.handle(notification)
    }
}
