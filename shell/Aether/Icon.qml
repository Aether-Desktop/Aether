import QtQuick
import QtQuick.Effects

// Bundled monochrome AETHER icon, tinted at runtime.
Item {
    id: root

    property string name: ""
    property color color: Theme.onSurface
    property int size: 18
    property real opacityOverride: 1.0

    implicitWidth: root.size
    implicitHeight: root.size
    opacity: root.opacityOverride

    Image {
        id: image
        anchors.fill: parent
        source: root.name.length > 0 ? Qt.resolvedUrl("icons/" + root.name + ".svg") : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        visible: false
        asynchronous: true
    }

    MultiEffect {
        anchors.fill: parent
        source: image
        visible: image.status === Image.Ready
        colorizationColor: root.color
        colorization: 1.0
    }
}
