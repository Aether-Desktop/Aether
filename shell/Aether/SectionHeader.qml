import QtQuick

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property string actionText: ""
    property int titleSize: 15

    signal actionClicked()

    implicitHeight: root.subtitle.length > 0 ? 48 : 30

    Column {
        anchors.left: parent.left
        anchors.right: action.visible ? action.left : parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text {
            text: root.title
            color: Theme.onSurface
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fs(root.titleSize)
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            width: parent.width
        }
        Text {
            visible: root.subtitle.length > 0
            text: root.subtitle
            color: Theme.onSurfaceVariant
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fs(11.5)
            elide: Text.ElideRight
            width: parent.width
        }
    }

    Text {
        id: action
        visible: root.actionText.length > 0
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.actionText
        color: Theme.primary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fs(12)
        font.weight: Font.DemiBold
        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: root.actionClicked()
        }
    }
}
