import QtQuick

// Filled tonal button used across shell and apps.
Item {
    id: root

    property string label: ""
    property string icon: ""
    property bool primary: true
    property bool enabled: true
    property bool destructive: false

    signal clicked()

    implicitHeight: 40
    implicitWidth: Math.max(96, row.implicitWidth + 32)
    opacity: root.enabled ? 1 : 0.42

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusFull
        color: {
            if (root.destructive) return hover.hovered ? Qt.lighter(Theme.error, 1.08) : Theme.error;
            if (root.primary) return hover.hovered ? Qt.lighter(Theme.primary, 1.08) : Theme.primary;
            return hover.hovered ? Theme.surfaceContainerHighest : Theme.surfaceContainer;
        }
        scale: press.pressed ? 0.97 : 1.0
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
        Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Icon {
            visible: root.icon.length > 0
            name: root.icon
            size: 16
            color: root.destructive ? Theme.onPrimary
                : (root.primary ? Theme.onPrimary : Theme.onSurface)
        }
        Text {
            text: root.label
            color: root.destructive ? Theme.onPrimary
                : (root.primary ? Theme.onPrimary : Theme.onSurface)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fs(13)
            font.weight: Font.DemiBold
        }
    }

    HoverHandler { enabled: root.enabled; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: press; enabled: root.enabled; acceptedButtons: Qt.LeftButton; onTapped: root.clicked() }
    Accessible.role: Accessible.Button
    Accessible.name: root.label
}
