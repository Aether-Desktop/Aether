import QtQuick
import QtQuick.Layouts
import "../../../shell/Aether"

Item {
    id: root

    property string title: ""
    property string description: ""
    property string value: ""
    property string placeholder: ""
    property bool numeric: false

    signal edited(string value)

    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 4

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
        Rectangle {
            Layout.fillWidth: true
            height: 36
            radius: Theme.radiusSm
            color: Theme.surfaceContainerHighest
            border.width: 1
            border.color: input.activeFocus ? Theme.primary : Theme.hairline
            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.onSurface
                selectionColor: Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fs(12)
                inputMethodHints: root.numeric ? Qt.ImhFormattedNumbersOnly : Qt.ImhNone
                onEditingFinished: root.edited(text)
                onAccepted: root.edited(text)
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
                visible: input.text.length === 0
                text: root.placeholder
                color: Theme.onSurfaceVariant
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fs(12)
                opacity: 0.7
            }
        }
    }

    Component.onCompleted: input.text = root.value
    onValueChanged: {
        if (!input.activeFocus && input.text !== root.value) input.text = root.value;
    }
}
