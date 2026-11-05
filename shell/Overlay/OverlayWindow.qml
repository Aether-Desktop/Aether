import QtQuick
import Quickshell
import Quickshell.Wayland
import "../Aether"

// Full-screen overlay host. One instance per monitor; only the monitor named in
// UiState.screenName (or the primary monitor as a fallback) draws the panel.
PanelWindow {
    id: win

    required property var screenInfo

    readonly property bool isPrimary: Quickshell.screens.length > 0
        && Quickshell.screens[0].name === root.screenInfo.name
    readonly property bool enabledForScreen: UiState.screenName.length > 0
        ? UiState.screenName === root.screenInfo.name
        : root.isPrimary
    readonly property bool active: UiState.panel !== "" && root.enabledForScreen

    screen: root.screenInfo
    color: "transparent"
    visible: root.active
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.namespace: "aether-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    focusable: root.active

    onActiveChanged: {
        if (!root.active) return;
        Qt.callLater(() => {
            focusScope.forceActiveFocus();
        });
    }

    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: root.active
        Keys.onEscapePressed: UiState.close()

        // Dimmed, click-through-to-close backdrop.
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Theme.scrim.r, Theme.scrim.g, Theme.scrim.b, 0.42)
            opacity: root.active ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durationNormal } }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: UiState.close()
        }

        Loader {
            id: panelLoader
            anchors.fill: parent
            active: root.active
            asynchronous: true
            source: {
                switch (UiState.panel) {
                case "dashboard": return "Dashboard/Dashboard.qml";
                case "launcher": return "Launcher/Launcher.qml";
                case "quickSettings": return "QuickSettings/QuickSettings.qml";
                case "notifications": return "Notifications/NotificationCenter.qml";
                case "power": return "PowerMenu/PowerMenu.qml";
                default: return "";
                }
            }
            onLoaded: {
                if (!item) return;
                if (item.forceActiveFocus) item.forceActiveFocus();
                if (typeof item.opened === "function") item.opened();
            }
        }
    }
}
