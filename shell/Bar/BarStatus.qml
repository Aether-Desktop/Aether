import QtQuick
import QtQuick.Window
import "../Aether"

// Network / Bluetooth / volume / battery cluster.
Row {
    id: root

    required property var window
    property var screenInfo
    property bool showLabels: true
    spacing: 2

    // Wi-Fi / network
    Item {
        visible: Config.bar.showNetwork !== false
        width: 34
        height: 34
        IconButton {
            anchors.fill: parent
            icon: System.wifiEnabled && System.connected ? "wifi"
                : (System.wifiEnabled ? "wifi" : "wifi-off")
            tint: System.connected ? Theme.onSurface : Theme.onSurfaceVariant
            accessibleName: System.networkName || "Network"
            onClicked: {
                UiState.screenName = root.screenInfo ? root.screenInfo.name : "";
                UiState.toggle("quickSettings");
            }
        }
        Rectangle {
            visible: System.connected
            width: 5
            height: 5
            radius: 3
            color: Theme.success
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 7
        }
    }

    // Bluetooth
    IconButton {
        visible: Config.bar.showBluetooth !== false
        icon: "bluetooth"
        tint: System.bluetoothEnabled ? Theme.primary : Theme.onSurfaceVariant
        active: false
        accessibleName: "Bluetooth"
        onClicked: {
            if (!System.bluetoothAvailable) {
                UiState.showOsd("bluetooth", "Bluetooth unavailable", 0, true);
                return;
            }
            System.toggleBluetooth();
        }
    }

    // Volume with wheel support
    Item {
        visible: Config.bar.showVolume !== false
        width: 34
        height: 34

        IconButton {
            anchors.fill: parent
            icon: System.muted || System.volume <= 0.001 ? "volume-mute" : "volume"
            tint: System.muted ? Theme.onSurfaceVariant : Theme.onSurface
            accessibleName: "Volume " + System.volumePercent() + " percent"
            onClicked: {
                System.toggleMute();
                UiState.showOsd("volume", System.muted ? "Muted" : "Volume", System.volume, System.muted);
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: (wheel) => {
                const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                System.setVolume(System.volume + step);
                UiState.showOsd("volume", "Volume", System.volume, System.muted);
            }
        }
    }

    // Battery
    Item {
        visible: Config.bar.showBattery !== false && System.hasBattery
        width: System.hasBattery ? (statusRow.implicitWidth + 16) : 0
        height: 34

        Row {
            id: statusRow
            anchors.centerIn: parent
            spacing: 5
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: System.charging ? "power" : "battery"
                size: 15
                color: System.batteryLevel <= 0.15 && !System.charging ? Theme.error : Theme.onSurface
            }
            Text {
                visible: root.showLabels
                anchors.verticalCenter: parent.verticalCenter
                text: System.batteryPercent() + "%"
                color: System.batteryLevel <= 0.15 && !System.charging ? Theme.error : Theme.onSurfaceVariant
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fs(11)
                font.weight: Font.Medium
            }
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: {
                UiState.screenName = root.screenInfo ? root.screenInfo.name : "";
                UiState.open("quickSettings");
            }
        }
    }
}
