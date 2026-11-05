import QtQuick
import QtQuick.Layouts
import "../../../shell/Aether"

Item {
    id: root

    property string title: ""
    property string description: ""
    property string valueText: ""
    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0
    property bool available: true

    signal moved(real value)

    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                Layout.fillWidth: true
                text: root.title
                color: root.available ? Theme.onSurface : Theme.onSurfaceVariant
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fs(12)
                font.weight: Font.Medium
            }
            Text {
                text: root.valueText
                color: Theme.onSurfaceVariant
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fs(10.5)
            }
        }
        Text {
            Layout.fillWidth: true
            visible: root.description.length > 0
            text: root.description
            color: Theme.onSurfaceVariant
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fs(10)
            wrapMode: Text.WordWrap
        }
        Slider {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            value: root.value
            from: root.from
            to: root.to
            stepSize: root.stepSize
            enabled: root.available
            onMoved: (v) => root.moved(v)
        }
    }
}
