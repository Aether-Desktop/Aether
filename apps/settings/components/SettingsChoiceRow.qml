import QtQuick
import QtQuick.Layouts
import "../../../shell/Aether"

Item {
    id: root

    property string title: ""
    property string description: ""
    property var options: []
    property string current: ""

    signal chosen(string value)

    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 6

        Text {
            Layout.fillWidth: true
            text: root.title
            color: Theme.onSurface
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fs(12)
            font.weight: Font.Medium
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
        Flow {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: root.options
                delegate: Chip {
                    required property var modelData
                    readonly property string optionValue: typeof modelData === "string" ? modelData : modelData.value
                    readonly property string optionLabel: typeof modelData === "string" ? modelData : modelData.label
                    label: optionLabel
                    active: root.current === optionValue
                    onClicked: root.chosen(optionValue)
                }
            }
        }
    }
}
