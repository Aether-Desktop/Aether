import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../Aether"

// On-screen display for volume, brightness and toggle feedback.
PanelWindow {
    id: win

    required property var screenInfo

    readonly property bool isPrimary: Quickshell.screens.length > 0
        && Quickshell.screens[0].name === win.screenInfo.name

    screen: win.screenInfo
    color: "transparent"
    visible: win.isPrimary && UiState.osdVisible
    implicitWidth: 288
    implicitHeight: 70
    anchors {
        bottom: true
    }
    margins {
        bottom: 52
    }
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.namespace: "aether-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    focusable: false

    Surface {
        anchors.fill: parent
        fill: Theme.glassHigh
        radius: Theme.radiusLg
        padding: 12
        shadow: true
        shadowStrength: 0.3

        RowLayout {
            anchors.fill: parent
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                radius: 21
                color: Theme.primaryContainer
                Icon {
                    anchors.centerIn: parent
                    name: UiState.osdIcon
                    size: 20
                    color: Theme.primary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: UiState.osdTitle
                    color: Theme.onSurface
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(11.5)
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6

                    Rectangle {
                        anchors.fill: parent
                        radius: 3
                        color: Theme.surfaceContainerHighest
                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, UiState.osdValue))
                            height: parent.height
                            radius: parent.radius
                            color: Theme.primary
                            Behavior on width { NumberAnimation { duration: Theme.durationFast } }
                        }
                    }
                }

                Text {
                    text: UiState.osdBool
                        ? (UiState.osdValue > 0 ? "On" : "Off")
                        : Math.round(UiState.osdValue * 100) + "%"
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(9.5)
                }
            }
        }
    }
}
