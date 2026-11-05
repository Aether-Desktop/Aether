import QtQuick
import Quickshell
import Quickshell.Wayland
import "../Aether"
import "NotificationCard.qml"

// Transient notification popups, anchored under the bar on the primary monitor.
PanelWindow {
    id: win

    required property var screenInfo

    readonly property bool isPrimary: Quickshell.screens.length > 0
        && Quickshell.screens[0].name === win.screenInfo.name
    readonly property bool bottom: Config.notifications.position === "bottom-right"

    screen: win.screenInfo
    color: "transparent"
    visible: win.isPrimary && Notify.popups.length > 0
    implicitWidth: 360
    implicitHeight: column.implicitHeight + 8
    anchors {
        top: !win.bottom
        bottom: win.bottom
        right: true
    }
    margins {
        top: win.bottom ? 0 : 60
        bottom: win.bottom ? 60 : 0
        right: 12
    }
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.namespace: "aether-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    focusable: false

    Column {
        id: column
        width: parent.width
        spacing: 8

        Repeater {
            model: Notify.popups
            delegate: NotificationCard {
                required property var modelData
                width: column.width
                notification: modelData.n
                popupKey: modelData.key
                popup: true
            }
        }
    }
}
