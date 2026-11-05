import QtQuick

// Minimal horizontal slider with pointer drag and keyboard support.
Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0
    property color fillColor: Theme.primary
    property color trackColor: Theme.surfaceContainerHighest
    property bool enabled: true

    signal moved(real value)

    implicitHeight: 30
    opacity: root.enabled ? 1 : 0.4

    readonly property real normalised: root.to === root.from ? 0
        : Math.max(0, Math.min(1, (root.value - root.from) / (root.to - root.from)))

    function commit(px) {
        if (!root.enabled) return;
        const w = Math.max(1, track.width - knob.width);
        let n = Math.max(0, Math.min(1, (px - knob.width / 2) / w));
        if (root.stepSize > 0) {
            const steps = Math.round((root.to - root.from) / root.stepSize);
            n = Math.round(n * steps) / steps;
        }
        root.moved(root.from + n * (root.to - root.from));
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: root.trackColor

        Rectangle {
            width: Math.max(root.height - 16, track.width * root.normalised)
            height: parent.height
            radius: parent.radius
            color: root.fillColor
            Behavior on width { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing } }
        }
    }

    Rectangle {
        id: knob
        width: 16
        height: 16
        radius: 8
        anchors.verticalCenter: parent.verticalCenter
        x: root.normalised * (track.width - width)
        color: Theme.onSurface
        border.width: 2
        border.color: root.fillColor
        scale: dragArea.pressed ? 1.18 : 1.0
        Behavior on scale { NumberAnimation { duration: Theme.durationFast } }
        Behavior on x { enabled: !dragArea.pressed; NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing } }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        anchors.topMargin: -6
        anchors.bottomMargin: -6
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onPressed: (mouse) => root.commit(mouse.x)
        onPositionChanged: (mouse) => { if (pressed) root.commit(mouse.x); }
        onWheel: (wheel) => {
            const dir = wheel.angleDelta.y > 0 ? 1 : -1;
            root.moved(root.value + dir * (root.stepSize > 0 ? root.stepSize : (root.to - root.from) * 0.05));
        }
    }

    Keys.onLeftPressed: root.moved(Math.max(root.from, root.value - (root.stepSize || (root.to - root.from) * 0.05)))
    Keys.onRightPressed: root.moved(Math.min(root.to, root.value + (root.stepSize || (root.to - root.from) * 0.05)))

    Accessible.role: Accessible.Slider
    Accessible.name: "Slider"
}
