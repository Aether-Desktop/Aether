import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Aether"
import "../../Notifications"

// Notification centre: persistent history owned by the shared Notify server.
Item {
    id: root

    implicitWidth: 408
    implicitHeight: 660
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.rightMargin: 16
    anchors.topMargin: 60
    width: Math.min(root.implicitWidth, parent.width - 32)
    height: Math.min(root.implicitHeight, parent.height - 84)

    readonly property var items: Notify.history.slice().reverse()

    function opened() {}

    Surface {
        anchors.fill: parent
        fill: Theme.glassHigh
        padding: 14
        radius: Theme.radiusLg

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: "Notifications"
                        color: Theme.onSurface
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(16)
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: root.items.length + (root.items.length === 1 ? " item" : " items")
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(9.5)
                    }
                }
                Chip {
                    label: Notify.dnd ? "DND on" : "DND"
                    icon: "dnd"
                    active: Notify.dnd
                    onClicked: Notify.setDnd(!Notify.dnd)
                }
                IconButton {
                    icon: "trash"
                    iconSize: 15
                    buttonSize: 30
                    enabled: root.items.length > 0
                    accessibleName: "Clear all notifications"
                    onClicked: Notify.dismissAll()
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hairline }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: list.height
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: list
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.items
                        delegate: NotificationCard {
                            required property var modelData
                            width: list.width
                            notification: modelData
                        }
                    }

                    Column {
                        visible: root.items.length === 0
                        width: parent.width
                        spacing: 8
                        Item { width: 1; height: 90 }
                        Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: "bell"
                            size: 30
                            color: Theme.onSurfaceVariant
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Notify.dnd ? "Do not disturb is on" : "You're all caught up"
                            color: Theme.onSurface
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(12)
                            font.weight: Font.DemiBold
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.min(parent.width - 40, 260)
                            horizontalAlignment: Text.AlignHCenter
                            text: Notify.dnd
                                ? "New notifications are kept in history but will not pop up."
                                : "Notifications from applications will appear here."
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(10.5)
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hairline }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "History is kept for this session only."
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(9)
                }
                Button {
                    label: "Settings"
                    icon: "settings"
                    primary: false
                    implicitHeight: 28
                    onClicked: { UiState.close(); Quickshell.execDetached(["aether-settings"]); }
                }
            }
        }
    }
}
