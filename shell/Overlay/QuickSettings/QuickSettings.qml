import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Services.UPower
import "../../Aether"
import "ToggleTile.qml"

// Quick settings: connectivity, audio, night light, power profile and session actions.
Item {
    id: root

    implicitWidth: 404
    implicitHeight: 720
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.rightMargin: 16
    anchors.topMargin: 60
    width: Math.min(root.implicitWidth, parent.width - 32)
    height: Math.min(root.implicitHeight, parent.height - 84)

    property var pendingNetwork: null
    property string password: ""
    property string connectHint: ""

    readonly property var wifiNetworks: {
        const ns = System.wifiNetworks.slice();
        ns.sort((a, b) => ((b.connected ? 1 : 0) - (a.connected ? 1 : 0))
            || (b.signalStrength - a.signalStrength));
        return ns;
    }
    readonly property var pairedDevices: {
        const ds = System.btDevices;
        const out = [];
        for (let i = 0; i < ds.length; i++)
            if (ds[i].paired || ds[i].connected) out.push(ds[i]);
        out.sort((a, b) => (b.connected ? 1 : 0) - (a.connected ? 1 : 0));
        return out;
    }

    function opened() {
        root.pendingNetwork = null;
        root.connectHint = "";
        if (System.wifiAvailable && System.wifiEnabled) System.scanWifi();
    }

    function chooseNetwork(n) {
        if (!n) return;
        root.connectHint = "";
        if (n.connected) { n.disconnect(); return; }
        if (n.known || n.security === WifiSecurityType.Open) {
            System.connectWifi(n);
            root.pendingNetwork = null;
            return;
        }
        root.pendingNetwork = n;
        root.password = "";
        Qt.callLater(() => passwordField.forceActiveFocus());
    }

    function submitPassword() {
        if (!root.pendingNetwork) return;
        if (root.password.length === 0) {
            root.connectHint = "Enter the network password";
            return;
        }
        System.connectWifiPsk(root.pendingNetwork, root.password);
        root.pendingNetwork = null;
        root.password = "";
        root.connectHint = "Connecting…";
    }

    function signalIcon(strength) {
        return strength > 0.15 ? "wifi" : "wifi-off";
    }

    function securityLabel(n) {
        if (n.security === WifiSecurityType.Open) return "";
        if (n.security === WifiSecurityType.Owe) return "Enhanced Open";
        return "Secured";
    }

    Surface {
        anchors.fill: parent
        fill: Theme.glassHigh
        padding: 16
        radius: Theme.radiusLg

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Quick settings"
                    color: Theme.onSurface
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(16)
                    font.weight: Font.DemiBold
                }
                Text {
                    text: System.hostname
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(10)
                }
                IconButton {
                    icon: "settings"; iconSize: 16; buttonSize: 30
                    accessibleName: "Open AETHER Settings"
                    onClicked: { UiState.close(); Quickshell.execDetached(["aether-settings"]); }
                }
            }

            // ---------------- Toggles ----------------
            GridLayout {
                Layout.fillWidth: true
                columns: 3
                rowSpacing: 8
                columnSpacing: 8

                ToggleTile {
                    Layout.fillWidth: true
                    icon: System.wifiEnabled ? "wifi" : "wifi-off"
                    label: "Wi-Fi"
                    active: System.wifiEnabled
                    available: System.wifiAvailable
                    onToggled: {
                        System.toggleWifi();
                        UiState.showOsd("wifi", System.wifiEnabled ? "Wi-Fi off" : "Wi-Fi on", 0, true);
                    }
                }
                ToggleTile {
                    Layout.fillWidth: true
                    icon: "bluetooth"
                    label: "Bluetooth"
                    active: System.bluetoothEnabled
                    available: System.bluetoothAvailable
                    onToggled: System.toggleBluetooth()
                }
                ToggleTile {
                    Layout.fillWidth: true
                    icon: "nightlight"
                    label: "Night light"
                    active: Brightness.nightLight
                    onToggled: Brightness.setNightLight(!Brightness.nightLight)
                }
                ToggleTile {
                    Layout.fillWidth: true
                    icon: Theme.isLight ? "moon" : "sun"
                    label: Theme.isLight ? "Dark mode" : "Light mode"
                    active: !Theme.isLight
                    onToggled: Config.setTheme(Theme.isLight ? "aether-dark" : "aether-light")
                }
                ToggleTile {
                    Layout.fillWidth: true
                    icon: "dnd"
                    label: "Do not disturb"
                    active: Notify.dnd
                    onToggled: Notify.setDnd(!Notify.dnd)
                }
                ToggleTile {
                    Layout.fillWidth: true
                    icon: "activity"
                    label: "Power saver"
                    active: System.powerProfile === PowerProfile.PowerSaver
                    onToggled: System.setPowerProfile(
                        System.powerProfile === PowerProfile.PowerSaver
                            ? PowerProfile.Balanced : PowerProfile.PowerSaver)
                }
            }

            // ---------------- Volume / brightness ----------------
            Surface {
                Layout.fillWidth: true
                Layout.preferredHeight: 116
                radius: Theme.radiusMd
                fill: Theme.surfaceContainer
                padding: 12
                shadow: false

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        IconButton {
                            icon: System.muted ? "volume-mute" : "volume"
                            iconSize: 15; buttonSize: 26
                            accessibleName: System.muted ? "Unmute" : "Mute"
                            onClicked: System.toggleMute()
                        }
                        Text {
                            Layout.fillWidth: true
                            text: System.audioAvailable
                                ? (System.sinkName + (System.muted ? " · muted" : ""))
                                : "No audio output"
                            color: Theme.onSurface
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(11)
                            elide: Text.ElideRight
                        }
                        Text {
                            text: System.audioAvailable ? System.volumePercent() + "%" : "—"
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(10)
                        }
                    }
                    Slider {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        value: System.volume
                        from: 0
                        to: 1
                        stepSize: 0.02
                        enabled: System.audioAvailable
                        onMoved: (v) => {
                            System.setVolume(v);
                            UiState.showOsd("volume", "Volume", v, false);
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Icon { name: "sun"; size: 15; color: Theme.onSurfaceVariant }
                        Text {
                            Layout.fillWidth: true
                            text: Brightness.available ? "Brightness" : "Brightness unavailable (install brightnessctl)"
                            color: Brightness.available ? Theme.onSurface : Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(11)
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: Brightness.available
                            text: Math.round(Brightness.value * 100) + "%"
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(10)
                        }
                    }
                    Slider {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 22
                        value: Brightness.value
                        from: 0.01
                        to: 1
                        stepSize: 0.02
                        enabled: Brightness.available
                        onMoved: (v) => {
                            Brightness.set(v);
                            UiState.showOsd("sun", "Brightness", v, false);
                        }
                    }
                }
            }

            // ---------------- Power profile ----------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Text {
                    text: "Power"
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(10.5)
                    font.weight: Font.DemiBold
                }
                Item { Layout.fillWidth: true }
                Chip {
                    label: "Saver"
                    active: System.powerProfile === PowerProfile.PowerSaver
                    onClicked: System.setPowerProfile(PowerProfile.PowerSaver)
                }
                Chip {
                    label: "Balanced"
                    active: System.powerProfile === PowerProfile.Balanced
                    onClicked: System.setPowerProfile(PowerProfile.Balanced)
                }
                Chip {
                    label: "Performance"
                    visible: System.hasPerformanceProfile
                    active: System.powerProfile === PowerProfile.Performance
                    onClicked: System.setPowerProfile(PowerProfile.Performance)
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hairline }

            // ---------------- Scrolling connectivity ----------------
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: sections.height
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: sections
                    width: parent.width
                    spacing: 8

                    // Password prompt
                    Column {
                        visible: root.pendingNetwork !== null
                        width: parent.width
                        spacing: 6
                        Text {
                            text: "Password for " + (root.pendingNetwork ? root.pendingNetwork.name : "")
                            color: Theme.onSurface
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(11)
                            font.weight: Font.DemiBold
                        }
                        RowLayout {
                            width: parent.width
                            spacing: 6
                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: Theme.radiusSm
                                color: Theme.surfaceContainerHighest
                                border.width: 1
                                border.color: Theme.hairline
                                TextInput {
                                    id: passwordField
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    echoMode: TextInput.Password
                                    color: Theme.onSurface
                                    selectionColor: Theme.primary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(12)
                                    onTextChanged: root.password = text
                                    onAccepted: root.submitPassword()
                                }
                            }
                            Button {
                                label: "Connect"
                                implicitHeight: 32
                                onClicked: root.submitPassword()
                            }
                            IconButton {
                                icon: "close"; iconSize: 13; buttonSize: 30
                                accessibleName: "Cancel"
                                onClicked: { root.pendingNetwork = null; root.password = ""; }
                            }
                        }
                        Text {
                            visible: root.connectHint.length > 0
                            text: root.connectHint
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(9.5)
                        }
                    }

                    // Wi-Fi list
                    RowLayout {
                        width: parent.width
                        Text {
                            Layout.fillWidth: true
                            text: "Wi-Fi"
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(10.5)
                            font.weight: Font.DemiBold
                        }
                        Text {
                            visible: !System.networkAvailable
                            text: "NetworkManager unavailable"
                            color: Theme.error
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(9.5)
                        }
                        IconButton {
                            visible: System.wifiAvailable && System.wifiEnabled
                            icon: "search"; iconSize: 12; buttonSize: 24
                            accessibleName: "Scan for networks"
                            onClicked: System.scanWifi()
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 2
                        visible: System.wifiEnabled && System.wifiAvailable

                        Repeater {
                            model: root.wifiNetworks
                            delegate: Rectangle {
                                id: wifiRow
                                required property var modelData
                                readonly property bool requiresKey: modelData.security !== WifiSecurityType.Open
                                width: sections.width
                                height: 42
                                radius: Theme.radiusSm
                                color: wifiHover.hovered ? Theme.hover : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 6
                                    spacing: 9
                                    Icon {
                                        name: root.signalIcon(wifiRow.modelData.signalStrength)
                                        size: 15
                                        color: wifiRow.modelData.connected ? Theme.primary : Theme.onSurfaceVariant
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Text {
                                            Layout.fillWidth: true
                                            text: wifiRow.modelData.name || "Hidden network"
                                            color: Theme.onSurface
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fs(11.5)
                                            font.weight: wifiRow.modelData.connected ? Font.DemiBold : Font.Normal
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: root.securityLabel(wifiRow.modelData)
                                                + (wifiRow.modelData.connected ? (root.securityLabel(wifiRow.modelData).length > 0 ? " · connected" : "Connected") : "")
                                            color: wifiRow.modelData.connected ? Theme.primary : Theme.onSurfaceVariant
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fs(9)
                                            elide: Text.ElideRight
                                        }
                                    }
                                    Icon {
                                        visible: wifiRow.requiresKey
                                        name: "lock"
                                        size: 11
                                        color: Theme.onSurfaceVariant
                                    }
                                    Text {
                                        text: Math.round(wifiRow.modelData.signalStrength * 100) + "%"
                                        color: Theme.onSurfaceVariant
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fs(9)
                                    }
                                    IconButton {
                                        visible: wifiRow.modelData.connected
                                        icon: "close"; iconSize: 12; buttonSize: 26
                                        accessibleName: "Disconnect"
                                        onClicked: wifiRow.modelData.disconnect()
                                    }
                                }

                                HoverHandler { id: wifiHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler {
                                    acceptedButtons: Qt.LeftButton
                                    onTapped: root.chooseNetwork(wifiRow.modelData)
                                }
                            }
                        }

                        Text {
                            visible: root.wifiNetworks.length === 0
                            width: parent.width
                            text: "No networks found yet. Press scan."
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(10)
                        }
                    }

                    Text {
                        visible: !System.wifiEnabled
                        width: parent.width
                        text: "Wi-Fi is off."
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(10)
                    }

                    Rectangle { width: parent.width; height: 1; color: Theme.hairline; visible: System.bluetoothAvailable }

                    // Bluetooth list
                    Column {
                        width: parent.width
                        spacing: 2
                        visible: System.bluetoothAvailable

                        RowLayout {
                            width: parent.width
                            Text {
                                Layout.fillWidth: true
                                text: "Bluetooth devices"
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(10.5)
                                font.weight: Font.DemiBold
                            }
                            IconButton {
                                visible: System.bluetoothEnabled
                                icon: "search"; iconSize: 12; buttonSize: 24
                                accessibleName: "Scan for Bluetooth devices"
                                onClicked: if (System.btAdapter) System.btAdapter.discovering = !System.btAdapter.discovering
                            }
                        }

                        Repeater {
                            model: root.pairedDevices
                            delegate: Rectangle {
                                id: btRow
                                required property var modelData
                                width: sections.width
                                height: 42
                                radius: Theme.radiusSm
                                color: btHover.hovered ? Theme.hover : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 6
                                    spacing: 9
                                    Icon {
                                        name: "bluetooth"
                                        size: 15
                                        color: btRow.modelData.connected ? Theme.primary : Theme.onSurfaceVariant
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Text {
                                            Layout.fillWidth: true
                                            text: btRow.modelData.name || btRow.modelData.deviceName || "Bluetooth device"
                                            color: Theme.onSurface
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fs(11.5)
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: btRow.modelData.connected ? "Connected"
                                                : (btRow.modelData.paired ? "Paired" : "Available")
                                            color: btRow.modelData.connected ? Theme.primary : Theme.onSurfaceVariant
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fs(9)
                                        }
                                    }
                                    Text {
                                        visible: btRow.modelData.batteryAvailable
                                        text: Math.round(btRow.modelData.battery * 100) + "%"
                                        color: Theme.onSurfaceVariant
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fs(9)
                                    }
                                    IconButton {
                                        icon: btRow.modelData.connected ? "close" : "plus"
                                        iconSize: 12; buttonSize: 26
                                        accessibleName: btRow.modelData.connected ? "Disconnect" : "Connect"
                                        onClicked: System.toggleBluetoothDevice(btRow.modelData)
                                    }
                                }

                                HoverHandler { id: btHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler {
                                    acceptedButtons: Qt.LeftButton
                                    onTapped: System.toggleBluetoothDevice(btRow.modelData)
                                }
                            }
                        }

                        Text {
                            visible: root.pairedDevices.length === 0
                            width: parent.width
                            text: System.bluetoothEnabled ? "No paired devices." : "Bluetooth is off."
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(10)
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hairline }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Button {
                    Layout.fillWidth: true
                    label: "Settings"
                    icon: "settings"
                    primary: false
                    implicitHeight: 34
                    onClicked: { UiState.close(); Quickshell.execDetached(["aether-settings"]); }
                }
                Button {
                    label: "Lock"
                    icon: "lock"
                    primary: false
                    implicitHeight: 34
                    onClicked: { UiState.close(); Power.perform("lock"); }
                }
                Button {
                    label: "Power"
                    icon: "power"
                    primary: false
                    implicitHeight: 34
                    onClicked: UiState.open("power")
                }
            }
        }
    }
}
