import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../Aether"

// Floating/docked AETHER bar for a single monitor.
PanelWindow {
    id: win

    required property var screenInfo

    screen: root.screenInfo
    color: "transparent"
    visible: Config.bar.enabled && root.enabledForScreen
    implicitHeight: root.barHeight
    WlrLayershell.namespace: "aether-bar"
    WlrLayershell.layer: WlrLayer.Top
    exclusionMode: Config.bar.exclusive === true ? ExclusionMode.Normal : ExclusionMode.Ignore
    exclusiveZone: Config.bar.exclusive === true ? root.barHeight : 0

    readonly property bool floating: Config.bar.mode !== "docked"
    readonly property bool showLabels: win.width > 1120
    readonly property bool enabledForScreen: {
        const list = Config.bar.monitors || [];
        if (list.length === 0) return true;
        return list.indexOf(root.screenInfo.name) !== -1;
    }
    readonly property int baseHeight: Math.max(34, Config.bar.height || 44)
    readonly property int margin: floating ? Math.max(0, Config.bar.margin || 8) : 0
    readonly property bool autoHide: Config.bar.autoHide === true
    property bool revealed: !win.autoHide
    readonly property int barHeight: win.autoHide && !win.revealed ? 5
        : win.baseHeight + (win.floating ? win.margin * 2 : 0)

    function openPanel(name) {
        UiState.screenName = win.screenInfo.name;
        UiState.toggle(name);
    }

    anchors {
        top: Config.bar.position !== "bottom"
        bottom: Config.bar.position === "bottom"
        left: true
        right: true
    }

    margins {
        top: win.floating && Config.bar.position !== "bottom" ? win.margin : 0
        bottom: win.floating && Config.bar.position === "bottom" ? win.margin : 0
        left: win.floating ? win.margin : 0
        right: win.floating ? win.margin : 0
    }

    // Auto-hide reveal strip and hover detection.
    HoverHandler {
        id: barHover
        enabled: win.autoHide
        onHoveredChanged: {
            if (hovered) win.revealed = true;
            else hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: 900
        onTriggered: if (!barHover.hovered) win.revealed = false
    }

    Rectangle {
        id: barSurface
        anchors.fill: parent
        anchors.topMargin: win.floating && win.revealed ? win.margin : 0
        anchors.bottomMargin: win.floating && win.revealed ? win.margin : 0
        radius: win.floating ? Theme.radiusFull : 0
        color: win.floating ? Theme.glass : Theme.glassHigh
        border.width: win.floating ? 1 : 0
        border.color: Theme.hairline
        opacity: win.autoHide && !win.revealed ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Theme.durationNormal } }

        Item {
            id: content
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8

            // ---------------- Left ----------------
            Row {
                id: leftCluster
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                IconButton {
                    icon: "launcher"
                    iconSize: 19
                    tint: Theme.primary
                    buttonSize: 34
                    accessibleName: "Open launcher"
                    onClicked: win.openPanel("launcher")
                }

                Workspaces {
                    id: workspaces
                    screenInfo: win.screenInfo
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Config.bar.showWorkspaces !== false && win.showLabels
                }

                Rectangle {
                    visible: Config.bar.showActiveWindow !== false && win.showLabels
                    width: visible ? Math.min(win.width * 0.26, activeLabel.implicitWidth + 24) : 0
                    height: 30
                    radius: Theme.radiusFull
                    color: Theme.surfaceContainer
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Icon {
                            name: "monitor"
                            size: 13
                            color: Theme.onSurfaceVariant
                        }
                        Text {
                            id: activeLabel
                            width: Math.min(implicitWidth, win.width * 0.22)
                            text: Hyprland.activeToplevel ? (Hyprland.activeToplevel.title || "Desktop") : "Desktop"
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(11.5)
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            // ---------------- Centre ----------------
            Row {
                anchors.centerIn: parent
                spacing: 12

                IconButton {
                    visible: Config.bar.showMedia !== false && System.hasMedia && win.showLabels
                    icon: System.playing ? "pause" : "play"
                    iconSize: 14
                    buttonSize: 30
                    accessibleName: "Play or pause"
                    active: System.playing
                    onClicked: System.togglePlay()
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: -2

                    Text {
                        id: clockText
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.onSurface
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(14)
                        font.weight: Font.DemiBold
                        text: Qt.formatDateTime(clock.date, Config.bar.clockFormat || "HH:mm")
                    }

                    Text {
                        id: dateText
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(9.5)
                        text: Qt.formatDateTime(clock.date, "ddd d MMM")
                        visible: win.showLabels
                    }

                    SystemClock {
                        id: clock
                        precision: Config.bar.clockSeconds === true ? SystemClock.Seconds : SystemClock.Minutes
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.openPanel("dashboard")
                    }
                }
            }

            // ---------------- Right ----------------
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                MediaMini {
                    visible: Config.bar.showMedia !== false && System.hasMedia && !win.showLabels
                    anchors.verticalCenter: parent.verticalCenter
                }

                BarStatus {
                    window: win
                    screenInfo: win.screenInfo
                    showLabels: win.showLabels
                    anchors.verticalCenter: parent.verticalCenter
                }

                Tray {
                    window: win
                    visible: Config.bar.showTray !== false
                    anchors.verticalCenter: parent.verticalCenter
                }

                NotificationBell {
                    screenInfo: win.screenInfo
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Config.bar.showNotifications !== false
                }

                IconButton {
                    icon: "sliders"
                    iconSize: 17
                    active: UiState.panel === "quickSettings"
                    accessibleName: "Quick settings"
                    onClicked: win.openPanel("quickSettings")
                }
            }
        }
    }
}
