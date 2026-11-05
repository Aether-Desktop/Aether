import QtQuick
import "../Aether"

// Compact now-playing button shown on narrower bars.
Item {
    id: root

    implicitWidth: 150
    implicitHeight: 32

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusFull
        color: hover.hovered ? Theme.hover : Theme.surfaceContainer
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 7

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: System.playing ? "music" : "pause"
            size: 13
            color: Theme.primary
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 22
            text: System.trackTitle || "Nothing playing"
            color: Theme.onSurface
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fs(11)
            elide: Text.ElideRight
        }
    }

    Rectangle {
        visible: System.trackLength > 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 8
        height: 2
        radius: 1
        color: Theme.hairline
        Rectangle {
            width: parent.width * Math.min(1, System.trackPosition / Math.max(1, System.trackLength))
            height: parent.height
            radius: 1
            color: Theme.primary
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { acceptedButtons: Qt.LeftButton; onTapped: UiState.open("dashboard") }
}
