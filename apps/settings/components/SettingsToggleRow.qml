import QtQuick
import QtQuick.Layouts
import "../../../shell/Aether"

Item {
    id: root

    property string title: ""
    property string description: ""
    property bool checked: false

    signal toggled(bool value)

    implicitHeight: Math.max(44, textColumn.implicitHeight)

    RowLayout {
        anchors.fill: parent
        spacing: 12

        ColumnLayout {
            id: textColumn
            Layout.fillWidth: true
            spacing: 1
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
        }

        Toggle {
            Layout.alignment: Qt.AlignVCenter
            checked: root.checked
            onToggled: (value) => root.toggled(value)
        }
    }
}
