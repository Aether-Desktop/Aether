pragma Singleton
import QtQuick

// Transient UI state shared by the bar, overlays and popups.
// Nothing here is persisted; persistent preferences live in Config.
QtObject {
    id: root

    // "" | "dashboard" | "launcher" | "quickSettings" | "notifications" | "power"
    property string panel: ""
    // Screen name that currently owns keyboard-driven overlays.
    property string screenName: ""
    property bool dashboardExpanded: false
    property bool launcherQueryFocused: false
    property bool dndPopupsMuted: false

    // Lightweight on-screen display for volume/brightness changes.
    property bool osdVisible: false
    property string osdIcon: "volume"
    property string osdTitle: "Volume"
    property real osdValue: 0.5
    property bool osdBool: false

    signal notificationArrived(var notification)

    function toggle(name) {
        if (root.panel === name) {
            root.close();
            return;
        }
        root.panel = name;
    }

    function open(name) {
        root.panel = name;
    }

    function close() {
        root.panel = "";
        root.dashboardExpanded = false;
        root.screenName = "";
    }

    function isOpen(name) {
        return root.panel === name;
    }

    function showOsd(icon, title, value, isBool) {
        root.osdIcon = icon;
        root.osdTitle = title;
        root.osdValue = value === undefined ? 0 : value;
        root.osdBool = isBool === true;
        root.osdVisible = true;
        osdTimer.restart();
    }

    property Timer osdTimer: Timer {
        interval: 1600
        onTriggered: root.osdVisible = false
    }
}
