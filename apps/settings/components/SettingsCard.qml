import QtQuick
import QtQuick.Layouts
import "../../../shell/Aether"

// Settings section card with an optional heading.
Surface {
    id: root

    property string title: ""
    property string description: ""

    implicitHeight: layout.implicitHeight + 32
    radius: Theme.radiusMd
    fill: Theme.surfaceContainer
    padding: 16
    shadow: false

    default property alias content: body.data

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 10

        ColumnLayout {
            visible: root.title.length > 0
            Layout.fillWidth: true
            spacing: 2
            Text {
                Layout.fillWidth: true
                text: root.title
                color: Theme.onSurface
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fs(13)
                font.weight: Font.DemiBold
            }
            Text {
                Layout.fillWidth: true
                visible: root.description.length > 0
                text: root.description
                color: Theme.onSurfaceVariant
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fs(10.5)
                wrapMode: Text.WordWrap
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: 10
        }
    }
}
