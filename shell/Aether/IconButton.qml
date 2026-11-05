import QtQuick

// Compact icon button with hover/press feedback and optional selected state.
Item {
    id: root

    property string icon: ""
    property int iconSize: 18
    property bool active: false
    property bool enabled: true
    property color tint: root.active ? Theme.primary : Theme.onSurface
    property color background: root.active ? Theme.selected
        : (hover.hovered ? Theme.hover : "transparent")
    property string accessibleName: ""
    property int buttonSize: 36

    signal clicked()

    implicitWidth: root.buttonSize
    implicitHeight: root.buttonSize
    opacity: root.enabled ? 1 : 0.4

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusFull
        color: root.background
        scale: press.pressed ? 0.92 : 1.0
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
        Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing } }
    }

    Icon {
        anchors.centerIn: parent
        name: root.icon
        size: root.iconSize
        color: root.tint
    }

    HoverHandler {
        id: hover
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: press
        enabled: root.enabled
        acceptedButtons: Qt.LeftButton
        onTapped: root.clicked()
    }

    Accessible.role: Accessible.Button
    Accessible.name: root.accessibleName.length > 0 ? root.accessibleName : root.icon
}
