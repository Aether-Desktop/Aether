import QtQuick

// Selectable pill/chip.
Item {
    id: root

    property string label: ""
    property string icon: ""
    property bool active: false
    property bool enabled: true

    signal clicked()

    implicitHeight: 32
    implicitWidth: row.implicitWidth + 24
    opacity: root.enabled ? 1 : 0.45

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusFull
        color: root.active ? Theme.selected : (hover.hovered ? Theme.hover : Theme.surfaceContainer)
        border.width: 1
        border.color: root.active ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35) : Theme.hairline
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Icon {
            visible: root.icon.length > 0
            name: root.icon
            size: 14
            color: root.active ? Theme.primary : Theme.onSurfaceVariant
        }
        Text {
            text: root.label
            color: root.active ? Theme.primary : Theme.onSurfaceVariant
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fs(12.5)
            font.weight: root.active ? Font.DemiBold : Font.Medium
        }
    }

    HoverHandler { enabled: root.enabled; cursorShape: Qt.PointingHandCursor }
    TapHandler { enabled: root.enabled; acceptedButtons: Qt.LeftButton; onTapped: root.clicked() }
    Accessible.role: Accessible.RadioButton
    Accessible.name: root.label
    Accessible.checked: root.active
}
