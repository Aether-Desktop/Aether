import QtQuick

// Rounded, translucent AETHER surface with a soft ambient shadow.
// Children are laid out inside `padding`, relative to the content item.
Rectangle {
    id: root

    property color fill: Theme.glass
    property color stroke: Theme.hairline
    property int radius: Theme.radiusLg
    property real padding: Theme.space("lg")
    property bool shadow: true
    property real shadowStrength: 0.22
    property int contentTopPadding: root.padding

    default property alias content: contentItem.data

    color: root.fill
    radius: root.radius
    border.width: root.stroke.a > 0 ? 1 : 0
    border.color: root.stroke
    antialiasing: true

    Rectangle {
        visible: root.shadow
        z: -1
        anchors.fill: parent
        anchors.margins: -3
        radius: root.radius + 3
        color: "#000000"
        opacity: root.shadowStrength
    }
    Rectangle {
        visible: root.shadow
        z: -2
        anchors.fill: parent
        anchors.margins: -9
        radius: root.radius + 9
        color: "#000000"
        opacity: root.shadowStrength * 0.35
    }

    Item {
        id: contentItem
        anchors.fill: parent
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        anchors.topMargin: root.contentTopPadding
        anchors.bottomMargin: root.padding
    }
}
