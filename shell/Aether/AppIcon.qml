import QtQuick
import Quickshell

// Desktop application icon with a graceful monogram fallback.
Item {
    id: root

    property string iconName: ""
    property string label: ""
    property int size: 32
    property color fallbackColor: Theme.primaryContainer
    property color fallbackTextColor: Theme.onPrimaryContainer

    implicitWidth: root.size
    implicitHeight: root.size

    readonly property string resolved: {
        if (!root.iconName) return "";
        if (root.iconName.indexOf("/") === 0) return root.iconName;
        return Quickshell.iconPath(root.iconName, true) || "";
    }

    Image {
        id: image
        anchors.fill: parent
        source: root.resolved ? (root.resolved.indexOf("file://") === 0 ? root.resolved : "file://" + root.resolved) : ""
        sourceSize.width: root.size * 2
        sourceSize.height: root.size * 2
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
        visible: status === Image.Ready
    }

    Rectangle {
        anchors.fill: parent
        visible: image.status !== Image.Ready
        radius: Math.round(root.size * 0.28)
        color: root.fallbackColor
        Text {
            anchors.centerIn: parent
            text: (root.label || "?").trim().charAt(0).toUpperCase()
            color: root.fallbackTextColor
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(root.size * 0.42)
            font.weight: Font.Bold
        }
    }
}
