import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../shell/Aether"
import "components"

// AETHER Settings application shell.
Item {
    id: root

    property string page: "appearance"

    readonly property var navGroups: [
        { label: "Personalisation", items: [
            { id: "appearance", label: "Appearance", icon: "palette", file: "AppearancePage" },
            { id: "bar", label: "Bar", icon: "layout", file: "BarPage" },
            { id: "dashboard", label: "Dashboard", icon: "grid", file: "DashboardPage" },
            { id: "notifications", label: "Notifications", icon: "bell", file: "NotificationsPage" }
        ] },
        { label: "System", items: [
            { id: "sound", label: "Sound", icon: "volume", file: "SoundPage" },
            { id: "network", label: "Network", icon: "wifi", file: "NetworkPage" },
            { id: "bluetooth", label: "Bluetooth", icon: "bluetooth", file: "BluetoothPage" },
            { id: "power", label: "Power", icon: "power", file: "PowerPage" }
        ] },
        { label: "Advanced", items: [
            { id: "hyprland", label: "Hyprland", icon: "monitor", file: "HyprlandPage" },
            { id: "about", label: "About", icon: "info", file: "AboutPage" }
        ] }
    ]

    readonly property var current: {
        for (let g = 0; g < root.navGroups.length; g++) {
            const items = root.navGroups[g].items;
            for (let i = 0; i < items.length; i++)
                if (items[i].id === root.page) return items[i];
        }
        return root.navGroups[0].items[0];
    }

    readonly property var subtitles: ({
        appearance: "Theme, accent, shape and typography",
        bar: "Layout and visible status items",
        dashboard: "Weather location, calendar and system cards",
        notifications: "Do not disturb, popups and history",
        sound: "PipeWire outputs, inputs and levels",
        network: "NetworkManager Wi-Fi and wired connections",
        bluetooth: "Adapters, pairing and connected devices",
        power: "Battery, profiles, brightness and night light",
        hyprland: "Compositor integration and generated config",
        about: "Version, links and diagnostics"
    })

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---------------- Sidebar ----------------
        Rectangle {
            Layout.preferredWidth: 248
            Layout.fillHeight: true
            color: Theme.surfaceContainer

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 12
                    spacing: 10
                    Rectangle {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        radius: Theme.radiusSm
                        color: Theme.primaryContainer
                        Image {
                            anchors.fill: parent
                            anchors.margins: 7
                            source: Qt.resolvedUrl("../../assets/branding/aether-mark.svg")
                            fillMode: Image.PreserveAspectFit
                            sourceSize.width: 48
                            sourceSize.height: 48
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Text {
                            text: "AETHER"
                            color: Theme.onSurface
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(15)
                            font.weight: Font.Bold
                            font.letterSpacing: 1.6
                        }
                        Text {
                            text: "Settings"
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(10)
                        }
                    }
                }

                Repeater {
                    model: root.navGroups
                    delegate: ColumnLayout {
                        id: group
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            Layout.topMargin: 10
                            Layout.bottomMargin: 3
                            text: group.modelData.label
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(9)
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.9
                        }

                        Repeater {
                            model: group.modelData.items
                            delegate: Rectangle {
                                id: navItem
                                required property var modelData
                                readonly property bool active: root.page === navItem.modelData.id
                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                radius: Theme.radiusSm
                                color: navItem.active ? Theme.selected
                                    : (navHover.hovered ? Theme.hover : "transparent")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 9
                                    anchors.rightMargin: 9
                                    spacing: 9
                                    Icon {
                                        name: navItem.modelData.icon
                                        size: 15
                                        color: navItem.active ? Theme.primary : Theme.onSurfaceVariant
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: navItem.modelData.label
                                        color: navItem.active ? Theme.onSurface : Theme.onSurfaceVariant
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fs(11.5)
                                        font.weight: navItem.active ? Font.DemiBold : Font.Normal
                                    }
                                }

                                HoverHandler { id: navHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler {
                                    acceptedButtons: Qt.LeftButton
                                    onTapped: root.page = navItem.modelData.id
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.hairline
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Icon { name: "sparkles"; size: 13; color: Theme.primary }
                    Text {
                        Layout.fillWidth: true
                        text: "AETHER 1.0.0"
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(9.5)
                    }
                    IconButton {
                        icon: "external"; iconSize: 12; buttonSize: 24
                        accessibleName: "Open documentation"
                        onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/aether-desktop/aether"])
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                width: 1
                height: parent.height
                color: Theme.hairline
            }
        }

        // ---------------- Content ----------------
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 84
                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 32
                    anchors.rightMargin: 32
                    anchors.bottomMargin: 14
                    spacing: 2
                    Text {
                        text: root.current.label
                        color: Theme.onSurface
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(22)
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: root.subtitles[root.current.id] || ""
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(11.5)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.hairline
            }

            Flickable {
                id: flick
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: (pageLoader.item ? pageLoader.item.implicitHeight : 0) + 48
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                Loader {
                    id: pageLoader
                    x: 32
                    y: 24
                    width: flick.width - 64
                    source: "pages/" + root.current.file + ".qml"
                    asynchronous: true
                }
            }
        }
    }
}
