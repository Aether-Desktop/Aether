import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import "../../../shell/Aether"
import "../components"

Item {
    id: page

    implicitHeight: col.implicitHeight

    property var pendingNetwork: null
    property string password: ""
    property string hint: ""
    property bool busy: false

    readonly property var wirelessNetworks: {
        const list = System.wifiNetworks.slice();
        list.sort((a, b) =>
            ((b.connected ? 1 : 0) - (a.connected ? 1 : 0))
            || ((b.known ? 1 : 0) - (a.known ? 1 : 0))
            || (b.signalStrength - a.signalStrength));
        return list;
    }

    readonly property bool wiredConnected: System.wiredDevice !== null
        && System.wiredDevice.connected

    function choose(network) {
        if (!network) return;
        page.hint = "";
        if (network.connected) {
            network.disconnect();
            page.hint = "Disconnecting from " + network.name;
            return;
        }
        if (network.known || network.security === WifiSecurityType.Open
                || network.security === WifiSecurityType.Owe) {
            System.connectWifi(network);
            page.pendingNetwork = null;
            page.hint = "Connecting to " + network.name;
            return;
        }
        const pskCapable = network.security === WifiSecurityType.WpaPsk
            || network.security === WifiSecurityType.Wpa2Psk
            || network.security === WifiSecurityType.Sae;
        if (!pskCapable) {
            // Enterprise and legacy WEP networks need the NetworkManager secrets
            // agent; connect() lets that agent collect credentials.
            System.connectWifi(network);
            page.pendingNetwork = null;
            page.hint = "Connecting to " + network.name + " — a secrets agent may ask for credentials";
            return;
        }
        page.pendingNetwork = network;
        page.password = "";
        Qt.callLater(() => passwordField.forceActiveFocus());
    }

    function submitPassword() {
        if (!page.pendingNetwork) return;
        if (page.password.length === 0) {
            page.hint = "Enter the network password";
            return;
        }
        System.connectWifiPsk(page.pendingNetwork, page.password);
        page.hint = "Connecting to " + page.pendingNetwork.name;
        page.pendingNetwork = null;
        page.password = "";
    }

    function securityLabel(network) {
        switch (network.security) {
        case WifiSecurityType.Open: return "Open";
        case WifiSecurityType.Owe: return "Enhanced Open";
        case WifiSecurityType.WpaPsk: return "WPA";
        case WifiSecurityType.Wpa2Psk: return "WPA2";
        case WifiSecurityType.Sae: return "WPA3";
        case WifiSecurityType.Wpa2Eap: return "WPA2 Enterprise";
        case WifiSecurityType.WpaEap: return "WPA Enterprise";
        case WifiSecurityType.StaticWep:
        case WifiSecurityType.DynamicWep: return "WEP";
        default: return "Secured";
        }
    }

    function signalText(network) {
        return Math.round((network.signalStrength || 0) * 100) + "%";
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 14

        SettingsCard {
            title: "Wi-Fi"
            description: "Backed by NetworkManager through Quickshell. Hidden networks are not listed until NetworkManager knows them."
            Layout.fillWidth: true

            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Wi-Fi radio"
                description: System.wifiAvailable
                    ? (System.wifiHardwareEnabled ? "Hardware radio is available." : "The hardware switch is off.")
                    : "No Wi-Fi device was detected."
                checked: System.wifiEnabled
                onToggled: (value) => System.setWifi(value)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: System.wifiAvailable
                        ? (System.wifiEnabled
                            ? (System.activeWifi
                                ? "Connected to “" + System.activeWifi.name + "” · " + System.wifiSignal + "% signal"
                                : "Not connected")
                            : "Radio is off")
                        : "Wi-Fi unavailable"
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(10)
                }
                Button {
                    label: "Scan"
                    icon: "refresh"
                    primary: false
                    implicitHeight: 30
                    enabled: System.wifiAvailable && System.wifiEnabled
                    onClicked: {
                        System.scanWifi();
                        page.hint = "Scanning for networks…";
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: page.hint.length > 0
                text: page.hint
                color: page.hint.indexOf("failed") !== -1 || page.hint.indexOf("Enter") !== -1
                    ? Theme.error : Theme.onSurfaceVariant
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fs(9.5)
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth: true
                visible: page.pendingNetwork !== null
                Layout.preferredHeight: passwordColumn.implicitHeight + 24
                radius: Theme.radiusSm
                color: Theme.surfaceContainerHigh

                ColumnLayout {
                    id: passwordColumn
                    width: parent.width - 24
                    x: 12
                    y: 12
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: "Password for “" + (page.pendingNetwork ? page.pendingNetwork.name : "") + "”"
                        color: Theme.onSurface
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(11.5)
                        font.weight: Font.DemiBold
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 34
                        radius: Theme.radiusSm
                        color: Theme.surfaceContainerHighest
                        border.width: 1
                        border.color: passwordField.activeFocus ? Theme.primary : Theme.hairline
                        TextInput {
                            id: passwordField
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.onSurface
                            selectionColor: Theme.primary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(12)
                            echoMode: TextInput.Password
                            onAccepted: page.submitPassword()
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Item { Layout.fillWidth: true }
                        Button {
                            label: "Cancel"
                            primary: false
                            implicitHeight: 30
                            onClicked: { page.pendingNetwork = null; page.password = ""; }
                        }
                        Button {
                            label: "Connect"
                            icon: "check"
                            implicitHeight: 30
                            onClicked: page.submitPassword()
                        }
                    }
                }
            }
        }

        SettingsCard {
            title: "Available networks"
            description: "Only networks reported by NetworkManager are shown."
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: page.wirelessNetworks
                    delegate: Rectangle {
                        id: netRow
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        radius: Theme.radiusSm
                        color: netRow.modelData.connected ? Theme.selected
                            : (netHover.hovered ? Theme.hover : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Icon {
                                name: netRow.modelData.signalStrength > 0.15 ? "wifi" : "wifi-off"
                                size: 16
                                color: netRow.modelData.connected ? Theme.primary : Theme.onSurfaceVariant
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    Layout.fillWidth: true
                                    text: netRow.modelData.name || "Hidden network"
                                    color: Theme.onSurface
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(11.5)
                                    font.weight: netRow.modelData.connected ? Font.DemiBold : Font.Medium
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: page.securityLabel(netRow.modelData)
                                        + " · " + page.signalText(netRow.modelData)
                                        + (netRow.modelData.known ? " · saved" : "")
                                    color: Theme.onSurfaceVariant
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(9.5)
                                }
                            }
                            Text {
                                visible: netRow.modelData.connected
                                text: "Connected"
                                color: Theme.primary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(9)
                                font.weight: Font.DemiBold
                            }
                            Text {
                                visible: netRow.modelData.stateChanging
                                text: "working…"
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(9)
                            }
                        }

                        HoverHandler { id: netHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: page.choose(netRow.modelData)
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: page.wirelessNetworks.length === 0
                    text: System.wifiAvailable
                        ? (System.wifiEnabled
                            ? "No networks found yet. Scan to populate the list."
                            : "Enable Wi-Fi to see nearby networks.")
                        : "No Wi-Fi device was detected."
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(10)
                    wrapMode: Text.WordWrap
                }
            }
        }

        SettingsCard {
            title: "Wired connection"
            Layout.fillWidth: true

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Icon {
                    name: "globe"
                    size: 16
                    color: page.wiredConnected ? Theme.primary : Theme.onSurfaceVariant
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        Layout.fillWidth: true
                        text: System.wiredDevice
                            ? (System.wiredDevice.name || "Ethernet")
                            : "No wired device detected"
                        color: Theme.onSurface
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(11.5)
                        font.weight: Font.Medium
                    }
                    Text {
                        Layout.fillWidth: true
                        text: System.wiredDevice
                            ? (System.wiredDevice.connected
                                ? "Connected" + (System.wiredDevice.address
                                    ? " · " + System.wiredDevice.address : "")
                                : "Cable disconnected")
                            : "Connect a USB or PCI Ethernet adapter."
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(9.5)
                    }
                }
                Button {
                    visible: System.wiredDevice !== null
                    label: System.wiredDevice && System.wiredDevice.connected ? "Disconnect" : "Connect"
                    primary: false
                    implicitHeight: 30
                    onClicked: {
                        if (!System.wiredDevice) return;
                        if (System.wiredDevice.connected) System.wiredDevice.disconnect();
                        else System.wiredDevice.connect();
                    }
                }
            }
        }

        SettingsCard {
            title: "Connectivity"
            Layout.fillWidth: true

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: "Backend"
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(10.5)
                }
                Text {
                    text: System.networkAvailable ? "NetworkManager" : "Unavailable"
                    color: System.networkAvailable ? Theme.onSurface : Theme.error
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(10.5)
                    font.weight: Font.DemiBold
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: "Internet reachability"
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(10.5)
                }
                Text {
                    text: NetworkConnectivity.toString(System.connectivity)
                    color: Theme.onSurface
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(10.5)
                    font.weight: Font.DemiBold
                }
            }
            Text {
                Layout.fillWidth: true
                text: "AETHER never stores Wi-Fi passwords itself. NetworkManager owns saved connection profiles."
                color: Theme.onSurfaceVariant
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fs(9.5)
                wrapMode: Text.WordWrap
            }
        }
    }
}
