import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "../../../shell/Aether"
import "../components"

Item {
    id: page

    implicitHeight: col.implicitHeight

    property var pendingForget: null
    property string hint: ""

    readonly property var pairedDevices: {
        const list = [];
        const all = System.btDevices;
        for (let i = 0; i < all.length; i++)
            if (all[i].paired || all[i].connected) list.push(all[i]);
        list.sort((a, b) => (b.connected ? 1 : 0) - (a.connected ? 1 : 0));
        return list;
    }

    readonly property var nearbyDevices: {
        const out = [];
        const all = System.btDevices;
        for (let i = 0; i < all.length; i++)
            if (!all[i].paired && !all[i].connected) out.push(all[i]);
        out.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        return out;
    }

    function stateLabel(device) {
        if (!device) return "";
        if (device.pairing) return "Pairing…";
        if (device.connected) return "Connected";
        if (device.paired) return "Paired";
        return "Available";
    }

    function toggleDevice(device) {
        if (!device) return;
        page.hint = "";
        if (device.pairing) {
            device.cancelPair();
            return;
        }
        if (device.connected) {
            device.disconnect();
            return;
        }
        if (device.paired) {
            device.connect();
            return;
        }
        device.pair();
        page.hint = "Pairing with " + device.name + " — confirm on the device if prompted.";
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 14

        SettingsCard {
            title: "Adapter"
            description: "Backed by BlueZ through Quickshell. Pairing prompts appear on the device itself."
            Layout.fillWidth: true

            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Bluetooth"
                description: System.bluetoothAvailable
                    ? (System.btAdapter.name || "Adapter detected")
                    : "No Bluetooth adapter was detected."
                checked: System.bluetoothEnabled
                onToggled: (value) => {
                    if (System.btAdapter) System.btAdapter.enabled = value;
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                SettingsToggleRow {
                    Layout.fillWidth: true
                    title: "Discoverable"
                    description: "Allow nearby devices to find this computer."
                    checked: System.btAdapter ? System.btAdapter.discoverable : false
                    onToggled: (value) => {
                        if (System.btAdapter) System.btAdapter.discoverable = value;
                    }
                }
                SettingsToggleRow {
                    Layout.fillWidth: true
                    title: "Scan for devices"
                    description: "Temporarily discover nearby Bluetooth devices."
                    checked: System.btAdapter ? System.btAdapter.discovering : false
                    onToggled: (value) => {
                        if (System.btAdapter) System.btAdapter.discovering = value;
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: page.hint.length > 0
                text: page.hint
                color: Theme.onSurfaceVariant
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fs(9.5)
                wrapMode: Text.WordWrap
            }
        }

        SettingsCard {
            title: "Paired devices"
            Layout.fillWidth: true

            Rectangle {
                Layout.fillWidth: true
                visible: page.pendingForget !== null
                Layout.preferredHeight: 52
                radius: Theme.radiusSm
                color: Theme.surfaceContainerHigh

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8
                    Icon { name: "trash"; size: 15; color: Theme.error }
                    Text {
                        Layout.fillWidth: true
                        text: "Forget “" + (page.pendingForget ? page.pendingForget.name : "") + "”? This removes the pairing."
                        color: Theme.onSurface
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(10.5)
                        wrapMode: Text.WordWrap
                    }
                    Button {
                        label: "Cancel"
                        primary: false
                        implicitHeight: 28
                        onClicked: page.pendingForget = null
                    }
                    Button {
                        label: "Forget"
                        destructive: true
                        implicitHeight: 28
                        onClicked: {
                            if (page.pendingForget) page.pendingForget.forget();
                            page.pendingForget = null;
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: page.pairedDevices
                    delegate: Rectangle {
                        id: deviceRow
                        required property var modelData
                        readonly property bool batteryKnown: deviceRow.modelData.batteryAvailable
                        Layout.fillWidth: true
                        Layout.preferredHeight: 54
                        radius: Theme.radiusSm
                        color: deviceRow.modelData.connected ? Theme.selected
                            : (deviceHover.hovered ? Theme.hover : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Icon {
                                name: "bluetooth"
                                size: 16
                                color: deviceRow.modelData.connected ? Theme.primary : Theme.onSurfaceVariant
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    Layout.fillWidth: true
                                    text: deviceRow.modelData.name || deviceRow.modelData.address
                                    color: Theme.onSurface
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(11.5)
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: page.stateLabel(deviceRow.modelData)
                                        + (deviceRow.batteryKnown
                                            ? " · " + Math.round(deviceRow.modelData.battery * 100) + "% battery"
                                            : "")
                                        + (deviceRow.modelData.address
                                            ? " · " + deviceRow.modelData.address : "")
                                    color: Theme.onSurfaceVariant
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(9.5)
                                    elide: Text.ElideRight
                                }
                            }
                            Button {
                                label: deviceRow.modelData.pairing ? "Cancel"
                                    : (deviceRow.modelData.connected ? "Disconnect"
                                    : (deviceRow.modelData.paired ? "Connect" : "Pair"))
                                primary: false
                                implicitHeight: 30
                                onClicked: page.toggleDevice(deviceRow.modelData)
                            }
                            IconButton {
                                icon: "trash"; iconSize: 14; buttonSize: 28
                                accessibleName: "Forget device"
                                onClicked: page.pendingForget = deviceRow.modelData
                            }
                        }

                        HoverHandler { id: deviceHover; cursorShape: Qt.PointingHandCursor }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: page.pairedDevices.length === 0
                    text: System.bluetoothAvailable
                        ? "No paired devices yet. Enable scanning and pair a device below."
                        : "Bluetooth is unavailable on this system."
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(10)
                    wrapMode: Text.WordWrap
                }
            }
        }

        SettingsCard {
            title: "Nearby devices"
            description: "Devices appear here while the adapter is discovering."
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: page.nearbyDevices
                    delegate: Rectangle {
                        id: nearbyRow
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        radius: Theme.radiusSm
                        color: nearbyHover.hovered ? Theme.hover : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10
                            Icon { name: "bluetooth"; size: 16; color: Theme.onSurfaceVariant }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    Layout.fillWidth: true
                                    text: nearbyRow.modelData.name || nearbyRow.modelData.address
                                    color: Theme.onSurface
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(11.5)
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: page.stateLabel(nearbyRow.modelData)
                                        + (nearbyRow.modelData.address
                                            ? " · " + nearbyRow.modelData.address : "")
                                    color: Theme.onSurfaceVariant
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(9.5)
                                    elide: Text.ElideRight
                                }
                            }
                            Button {
                                label: nearbyRow.modelData.pairing ? "Cancel" : "Pair"
                                primary: false
                                implicitHeight: 30
                                onClicked: page.toggleDevice(nearbyRow.modelData)
                            }
                        }

                        HoverHandler { id: nearbyHover; cursorShape: Qt.PointingHandCursor }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: page.nearbyDevices.length === 0
                    text: System.bluetoothAvailable
                        ? "No nearby devices. Turn on scanning to look for them."
                        : "Bluetooth is unavailable on this system."
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(10)
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
