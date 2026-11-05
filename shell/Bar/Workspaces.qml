import QtQuick
import Quickshell.Hyprland
import "../Aether"

// Hyprland workspace indicator. The active workspace expands into a labelled pill.
Item {
    id: root

    required property var screenInfo
    property int count: Config.bar.workspaceCount || 6

    implicitWidth: row.implicitWidth
    implicitHeight: 32

    readonly property var monitor: Hyprland.monitorFor(root.screenInfo)
    readonly property int activeId: root.monitor && root.monitor.activeWorkspace
        ? root.monitor.activeWorkspace.id : 1
    readonly property var occupied: {
        const out = [];
        const ws = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        for (let i = 0; i < ws.length; i++) out.push(ws[i].id);
        return out;
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: root.count
            delegate: Item {
                id: wsItem
                required property int index
                readonly property bool active: root.activeId === (index + 1)
                readonly property bool used: root.occupied.indexOf(index + 1) !== -1
                width: active ? 28 : 16
                height: 28
                Behavior on width { NumberAnimation { duration: Theme.durationNormal; easing.type: Theme.easingEmphasized } }

                Rectangle {
                    anchors.centerIn: parent
                    width: wsItem.active ? parent.width : (wsItem.used ? 7 : 5)
                    height: wsItem.active ? parent.height : width
                    radius: width / 2
                    color: wsItem.active ? Theme.primary
                        : (wsItem.used ? Theme.onSurfaceVariant : Theme.hairline)
                    opacity: wsItem.active ? 1 : (hover.hovered ? 0.95 : 0.65)
                    Behavior on width { NumberAnimation { duration: Theme.durationNormal; easing.type: Theme.easingEmphasized } }
                    Behavior on height { NumberAnimation { duration: Theme.durationNormal } }
                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                    Text {
                        anchors.centerIn: parent
                        visible: wsItem.active
                        text: wsItem.index + 1
                        color: Theme.onPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(11)
                        font.weight: Font.Bold
                    }
                }

                HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: Hyprland.dispatch("workspace " + (wsItem.index + 1))
                }
            }
        }
    }
}
