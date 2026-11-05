import QtQuick
import "../Aether"

// Bell button with an unread badge backed by the shared Notify singleton.
Item {
    id: root

    required property var screenInfo

    implicitWidth: 34
    implicitHeight: 34

    readonly property int count: Notify.count

    IconButton {
        anchors.fill: parent
        icon: "bell"
        tint: root.count > 0 ? Theme.onSurface : Theme.onSurfaceVariant
        active: UiState.panel === "notifications"
        accessibleName: "Notifications, " + root.count + " items"
        onClicked: {
            UiState.screenName = root.screenInfo ? root.screenInfo.name : "";
            UiState.toggle("notifications");
        }
    }

    Rectangle {
        visible: root.count > 0
        width: 16
        height: 16
        radius: 8
        color: Theme.error
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 3
        Text {
            anchors.centerIn: parent
            text: root.count > 9 ? "9+" : String(root.count)
            color: Theme.onPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fs(8)
            font.weight: Font.Bold
        }
    }
}
