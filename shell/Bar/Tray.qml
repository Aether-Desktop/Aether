import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../Aether"

// System tray, rendered with real StatusNotifierItem data.
Row {
    id: root

    required property var window
    spacing: 2
    visible: SystemTray.items && SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items ? SystemTray.items.values : []
        delegate: Item {
            id: trayItem
            required property var modelData
            width: 30
            height: 34

            readonly property string iconSource: {
                if (!trayItem.modelData || !trayItem.modelData.icon) return "";
                const i = trayItem.modelData.icon;
                if (i.indexOf("/") === 0) return "file://" + i;
                const p = Quickshell.iconPath(i, true);
                return p ? "file://" + p : "";
            }

            Image {
                anchors.centerIn: parent
                width: 17
                height: 17
                source: trayItem.iconSource
                sourceSize.width: 34
                sourceSize.height: 34
                smooth: true
                visible: status === Image.Ready
            }

            // Fallback: first letter of the item title.
            Text {
                anchors.centerIn: parent
                visible: trayItem.iconSource === ""
                text: (trayItem.modelData.title || "?").charAt(0).toUpperCase()
                color: Theme.onSurfaceVariant
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fs(11)
                font.weight: Font.Bold
            }

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusFull
                color: hover.hovered ? Theme.hover : "transparent"
            }

            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: (mouse) => {
                    if (!trayItem.modelData) return;
                    if (mouse.button === Qt.RightButton && trayItem.modelData.hasMenu) {
                        trayItem.modelData.display(root.window, mouse.x, mouse.y);
                    } else if (mouse.button === Qt.MiddleButton) {
                        trayItem.modelData.secondaryActivate();
                    } else {
                        trayItem.modelData.activate();
                    }
                }
            }
        }
    }
}
