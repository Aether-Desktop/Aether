import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Aether"

// Session power menu with an explicit confirmation step for destructive actions.
Item {
    id: root

    implicitWidth: 470
    implicitHeight: 430
    anchors.centerIn: parent
    width: Math.min(root.implicitWidth, parent.width - 48)
    height: Math.min(root.implicitHeight, parent.height - 120)

    property string pending: ""

    function activated(id) {
        if (Power.isDestructive(id)) {
            root.pending = id;
            return;
        }
        UiState.close();
        Power.perform(id);
    }

    function confirmPending() {
        const id = root.pending;
        root.pending = "";
        UiState.close();
        Power.perform(id);
    }

    Surface {
        anchors.fill: parent
        fill: Theme.glassHigh
        padding: 18
        radius: Theme.radiusLg

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Rectangle {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    radius: 21
                    color: Theme.primaryContainer
                    Icon {
                        anchors.centerIn: parent
                        name: "power"
                        size: 20
                        color: Theme.primary
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: "Session"
                        color: Theme.onSurface
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(17)
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: System.hostname + " · " + (System.hasBattery
                            ? "battery " + System.batteryPercent() + "%" : "desktop")
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(10.5)
                    }
                }
                IconButton {
                    icon: "close"
                    iconSize: 14
                    buttonSize: 30
                    accessibleName: "Close power menu"
                    onClicked: UiState.close()
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hairline }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4
                visible: root.pending.length === 0

                Repeater {
                    model: Power.actions
                    delegate: Rectangle {
                        id: actionRow
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 54
                        radius: Theme.radiusSm
                        color: actionHover.hovered
                            ? (Power.isDestructive(actionRow.modelData.id) ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : Theme.hover)
                            : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                radius: 16
                                color: Power.isDestructive(actionRow.modelData.id)
                                    ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.16)
                                    : Theme.surfaceContainerHigh
                                Icon {
                                    anchors.centerIn: parent
                                    name: actionRow.modelData.icon
                                    size: 16
                                    color: Power.isDestructive(actionRow.modelData.id) ? Theme.error : Theme.onSurface
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    text: actionRow.modelData.label
                                    color: Power.isDestructive(actionRow.modelData.id) ? Theme.error : Theme.onSurface
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(12.5)
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: actionRow.modelData.description
                                    color: Theme.onSurfaceVariant
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(9.5)
                                }
                            }

                            Icon {
                                name: "chevron-right"
                                size: 15
                                color: Theme.onSurfaceVariant
                            }
                        }

                        HoverHandler { id: actionHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: root.activated(actionRow.modelData.id)
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10
                visible: root.pending.length > 0

                Item { Layout.fillHeight: true }
                Icon {
                    Layout.alignment: Qt.AlignHCenter
                    name: root.pending === "logout" ? "logout" : (root.pending === "reboot" ? "reboot" : "shutdown")
                    size: 34
                    color: Theme.error
                }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Power.confirmLabel(root.pending) + "?"
                    color: Theme.onSurface
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(18)
                    font.weight: Font.DemiBold
                }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.pending === "logout"
                        ? "All applications in this session will close."
                        : "Make sure your work is saved. This cannot be undone."
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(11)
                    wrapMode: Text.WordWrap
                }
                Item { Layout.fillHeight: true }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Button {
                        Layout.fillWidth: true
                        label: "Cancel"
                        primary: false
                        onClicked: root.pending = ""
                    }
                    Button {
                        Layout.fillWidth: true
                        label: Power.confirmLabel(root.pending)
                        icon: "check"
                        destructive: true
                        onClicked: root.confirmPending()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.hairline
                visible: root.pending.length === 0
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.pending.length === 0
                spacing: 6
                Button {
                    Layout.fillWidth: true
                    label: "Reload shell"
                    icon: "activity"
                    primary: false
                    implicitHeight: 32
                    onClicked: { UiState.close(); Power.perform("reload"); }
                }
                Button {
                    Layout.fillWidth: true
                    label: "Settings"
                    icon: "settings"
                    primary: false
                    implicitHeight: 32
                    onClicked: { UiState.close(); Quickshell.execDetached(["aether-settings"]); }
                }
            }
        }
    }
}
