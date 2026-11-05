import QtQuick
import "../../Aether"

// Large quick-settings toggle tile.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property bool active: false
    property bool available: true

    signal toggled()

    implicitHeight: 66
    opacity: root.available ? 1 : 0.45

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusMd
        color: root.active ? Theme.primaryContainer : (tileHover.hovered ? Theme.hover : Theme.surfaceContainerHigh)
        border.width: 1
        border.color: root.active ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4) : Theme.hairline
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }

    Column {
        anchors.centerIn: parent
        spacing: 3
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 30
            height: 24
            Rectangle {
                anchors.centerIn: parent
                width: 26
                height: 26
                radius: 13
                color: root.active ? Theme.primary : Theme.surfaceContainerHighest
            }
            Icon {
                anchors.centerIn: parent
                name: root.icon
                size: 15
                color: root.active ? Theme.onPrimary : Theme.onSurfaceVariant
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: root.active ? Theme.onPrimaryContainer : Theme.onSurface
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fs(10.5)
            font.weight: Font.Medium
        }
    }

    HoverHandler {
        id: tileHover
        cursorShape: root.available ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
    TapHandler {
        enabled: root.available
        acceptedButtons: Qt.LeftButton
        onTapped: root.toggled()
    }
}
