import QtQuick
import QtQuick.Layouts
import "../../shell/Aether"

Item {
    id: root

    property string pendingAction: ""

    function choose(id) {
        if (Power.isDestructive(id)) {
            root.pendingAction = id;
            return;
        }
        Power.perform(id);
    }

    Shortcut {
        sequences: ["Escape"]
        onActivated: {
            if (root.pendingAction.length > 0) root.pendingAction = "";
            else Qt.quit();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: Theme.radiusSm
                color: Theme.primaryContainer
                Icon {
                    anchors.centerIn: parent
                    name: "power"
                    size: 19
                    color: Theme.primary
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    text: "Power"
                    color: Theme.onSurface
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.fs(17)
                    font.weight: Font.DemiBold
                }
                Text {
                    text: System.hostname
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(9.5)
                }
            }
            IconButton {
                icon: "close"; iconSize: 14; buttonSize: 28
                accessibleName: "Close"
                onClicked: Qt.quit()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: root.pendingAction.length > 0
            Layout.preferredHeight: visible ? 66 : 0
            radius: Theme.radiusSm
            color: Theme.surfaceContainerHigh

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4
                Text {
                    Layout.fillWidth: true
                    text: Power.confirmLabel(root.pendingAction) + " now?"
                    color: Theme.onSurface
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(11)
                    font.weight: Font.DemiBold
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        text: "Unsaved work may be lost."
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(9)
                    }
                    Button {
                        label: "Cancel"
                        primary: false
                        implicitHeight: 28
                        onClicked: root.pendingAction = ""
                    }
                    Button {
                        label: Power.confirmLabel(root.pendingAction)
                        destructive: true
                        implicitHeight: 28
                        onClicked: {
                            const id = root.pendingAction;
                            root.pendingAction = "";
                            Power.perform(id);
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: Power.actions
                delegate: Rectangle {
                    id: actionRow
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    radius: Theme.radiusSm
                    color: actionHover.hovered ? Theme.hover : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12
                        Rectangle {
                            width: 34
                            height: 34
                            radius: 10
                            color: actionRow.modelData.id === "shutdown"
                                ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.16)
                                : Theme.surfaceContainerHigh
                            Icon {
                                anchors.centerIn: parent
                                name: actionRow.modelData.icon
                                size: 16
                                color: actionRow.modelData.id === "shutdown"
                                    ? Theme.error : Theme.onSurface
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                Layout.fillWidth: true
                                text: actionRow.modelData.label
                                color: Theme.onSurface
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(12)
                                font.weight: Font.Medium
                            }
                            Text {
                                Layout.fillWidth: true
                                text: actionRow.modelData.description
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(9.5)
                            }
                        }
                        Icon {
                            name: "chevron-right"
                            size: 14
                            color: Theme.onSurfaceVariant
                            opacityOverride: actionHover.hovered ? 1 : 0.35
                        }
                    }

                    HoverHandler { id: actionHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: root.choose(actionRow.modelData.id)
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        Text {
            Layout.fillWidth: true
            text: "AETHER never runs these actions through a shell. Confirmation is required for log out, reboot and shut down."
            color: Theme.onSurfaceVariant
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fs(9)
            wrapMode: Text.WordWrap
        }
    }
}
