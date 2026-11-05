import QtQuick

// Material-style switch. The component never owns state: it emits `toggled` and the
// caller updates the source of truth.
Item {
    id: root

    property bool checked: false
    property bool enabled: true

    signal toggled(bool value)

    implicitWidth: 46
    implicitHeight: 28
    opacity: root.enabled ? 1 : 0.45

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.primary : Theme.surfaceContainerHighest
        Behavior on color { ColorAnimation { duration: Theme.durationNormal } }
    }

    Rectangle {
        width: 20
        height: 20
        radius: 10
        y: 4
        x: root.checked ? parent.width - width - 4 : 4
        color: root.checked ? Theme.onPrimary : Theme.onSurfaceVariant
        Behavior on x { NumberAnimation { duration: Theme.durationNormal; easing.type: Theme.easingEmphasized } }
        Behavior on color { ColorAnimation { duration: Theme.durationNormal } }
        Rectangle {
            anchors.centerIn: parent
            width: 4
            height: 4
            radius: 2
            color: root.checked ? Theme.primary : "transparent"
        }
    }

    HoverHandler { enabled: root.enabled; cursorShape: Qt.PointingHandCursor }
    TapHandler {
        enabled: root.enabled
        acceptedButtons: Qt.LeftButton
        onTapped: root.toggled(!root.checked)
    }
    Accessible.role: Accessible.CheckBox
    Accessible.name: "Toggle"
    Accessible.checked: root.checked
}
