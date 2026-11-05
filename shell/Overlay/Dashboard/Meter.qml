import QtQuick
import "../../Aether"

// Compact horizontal meter used on the dashboard and in System Monitor.
Item {
    id: root

    property string label: ""
    property string icon: ""
    property real value: 0
    property string valueText: ""
    property color accent: Theme.primary
    property int labelWidth: 86

    implicitHeight: 34

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Icon {
            visible: root.icon.length > 0
            name: root.icon
            size: 14
            color: Theme.onSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            width: root.labelWidth
            text: root.label
            color: Theme.onSurfaceVariant
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fs(11.5)
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: parent.width - root.labelWidth - 108
            height: 6
            radius: 3
            color: Theme.surfaceContainerHighest
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.value))
                height: parent.height
                radius: parent.radius
                color: root.accent
                Behavior on width { NumberAnimation { duration: Theme.durationNormal; easing.type: Theme.easing } }
            }
        }

        Text {
            width: 52
            horizontalAlignment: Text.AlignRight
            text: root.valueText
            color: Theme.onSurface
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fs(11.5)
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
