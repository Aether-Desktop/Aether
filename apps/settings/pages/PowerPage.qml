import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../../../shell/Aether"
import "../components"

Item {
    id: page

    implicitHeight: col.implicitHeight

    property string pendingAction: ""
    property string hint: ""

    readonly property var battery: System.batteryDevice

    function durationText(seconds) {
        if (!seconds || !isFinite(seconds) || seconds <= 0) return "";
        const mins = Math.round(seconds / 60);
        const h = Math.floor(mins / 60);
        const m = mins % 60;
        if (h <= 0) return m + " min";
        return h + " h " + (m < 10 ? "0" + m : m) + " min";
    }

    function batteryStateLabel() {
        switch (System.battery ? System.battery.state : UPowerDeviceState.Unknown) {
        case UPowerDeviceState.Charging: return "Charging";
        case UPowerDeviceState.Discharging: return "Discharging";
        case UPowerDeviceState.FullyCharged: return "Fully charged";
        case UPowerDeviceState.PendingCharge: return "Waiting to charge";
        case UPowerDeviceState.PendingDischarge: return "Waiting to discharge";
        case UPowerDeviceState.Empty: return "Empty";
        default: return "Unknown";
        }
    }

    function batteryEstimate() {
        if (!System.battery) return "";
        if (System.battery.state === UPowerDeviceState.Charging
                || System.battery.state === UPowerDeviceState.PendingCharge) {
            const t = page.durationText(System.battery.timeToFull);
            return t.length > 0 ? t + " until full" : "";
        }
        if (System.battery.state === UPowerDeviceState.Discharging) {
            const t = page.durationText(System.battery.timeToEmpty);
            return t.length > 0 ? t + " remaining" : "";
        }
        return "";
    }

    function profileName(profile) {
        return PowerProfile.toString(profile);
    }

    function requestAction(id) {
        page.hint = "";
        if (Power.isDestructive(id)) {
            page.pendingAction = id;
            return;
        }
        Power.perform(id);
    }

    function confirmAction() {
        const id = page.pendingAction;
        page.pendingAction = "";
        if (id.length > 0) Power.perform(id);
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 14

        SettingsCard {
            title: "Battery"
            description: System.hasBattery
                ? "Read directly from UPower."
                : "No battery was detected. This is normal on desktops."
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: System.hasBattery

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Icon {
                        name: System.charging ? "battery" : (System.batteryLevel <= 0.1 ? "battery" : "battery")
                        size: 18
                        color: System.charging ? Theme.success
                            : (System.batteryLevel <= 0.15 ? Theme.error : Theme.primary)
                    }
                    Text {
                        Layout.fillWidth: true
                        text: System.batteryPercent() + "% · " + page.batteryStateLabel()
                        color: Theme.onSurface
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(12)
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: page.batteryEstimate()
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(10)
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 8
                    radius: 4
                    color: Theme.surfaceContainerHighest
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, System.batteryLevel))
                        height: parent.height
                        radius: parent.radius
                        color: System.charging ? Theme.success
                            : (System.batteryLevel <= 0.15 ? Theme.error : Theme.primary)
                        Behavior on width { NumberAnimation { duration: Theme.durationNormal } }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        text: System.battery && System.battery.healthSupported
                            ? "Health " + Math.round(System.battery.healthPercentage) + "%"
                            : "Health not reported by this battery"
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(9.5)
                    }
                    Text {
                        visible: System.battery !== null && System.battery.model.length > 0
                        text: System.battery ? System.battery.model : ""
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(9.5)
                        elide: Text.ElideRight
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: !System.hasBattery
                text: "AETHER does not invent a battery reading when the firmware exposes none."
                color: Theme.onSurfaceVariant
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fs(10)
                wrapMode: Text.WordWrap
            }
        }

        SettingsCard {
            title: "Power profile"
            description: "Managed by power-profiles-daemon. The profile may be temporarily overridden by another application's hold."
            Layout.fillWidth: true

            Flow {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [
                        { profile: PowerProfile.PowerSaver, label: "Power saver" },
                        { profile: PowerProfile.Balanced, label: "Balanced" }
                    ]
                    delegate: Chip {
                        required property var modelData
                        label: modelData.label
                        icon: modelData.profile === PowerProfile.PowerSaver ? "battery" : "activity"
                        active: System.powerProfile === modelData.profile
                        onClicked: System.setPowerProfile(modelData.profile)
                    }
                }

                Chip {
                    label: "Performance"
                    icon: "sparkles"
                    active: System.powerProfile === PowerProfile.Performance
                    enabled: System.hasPerformanceProfile
                    onClicked: System.setPowerProfile(PowerProfile.Performance)
                }
            }

            Text {
                Layout.fillWidth: true
                text: System.hasPerformanceProfile
                    ? "Current profile: " + page.profileName(System.powerProfile)
                    : "This system does not expose a performance profile to power-profiles-daemon."
                color: Theme.onSurfaceVariant
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fs(9.5)
                wrapMode: Text.WordWrap
            }
        }

        SettingsCard {
            title: "Display"
            description: "Brightness uses brightnessctl; night light uses hyprsunset. Both are optional dependencies."
            Layout.fillWidth: true

            SettingsSliderRow {
                Layout.fillWidth: true
                title: "Brightness"
                value: Brightness.value
                from: 0.01
                to: 1
                stepSize: 0.01
                available: Brightness.available
                valueText: Brightness.available
                    ? Math.round(Brightness.value * 100) + "%"
                    : (Brightness.probed ? "brightnessctl unavailable" : "probing…")
                onMoved: (v) => Brightness.set(v)
            }

            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Night light"
                description: "Warm the screen through hyprsunset. Requires the hyprsunset package."
                checked: Brightness.nightLight
                onToggled: (value) => Brightness.setNightLight(value)
            }

            SettingsSliderRow {
                Layout.fillWidth: true
                title: "Night light temperature"
                description: "Lower values are warmer. 6500 K is neutral daylight."
                value: Brightness.nightLightTemperature
                from: 2500
                to: 6500
                stepSize: 100
                valueText: Math.round(Brightness.nightLightTemperature) + " K"
                onMoved: (v) => Brightness.setNightLightTemperature(v)
            }

            Text {
                Layout.fillWidth: true
                visible: !Brightness.available && Brightness.probed
                text: "brightnessctl was not found on PATH. Install it, or use your hardware keys, which AETHER does not intercept."
                color: Theme.onSurfaceVariant
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fs(9.5)
                wrapMode: Text.WordWrap
            }
        }

        SettingsCard {
            title: "Session"
            description: "Actions are executed as argument arrays, never through a shell."
            Layout.fillWidth: true

            Rectangle {
                Layout.fillWidth: true
                visible: page.pendingAction.length > 0
                Layout.preferredHeight: 56
                radius: Theme.radiusSm
                color: Theme.surfaceContainerHigh

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8
                    Icon { name: "power"; size: 15; color: Theme.error }
                    Text {
                        Layout.fillWidth: true
                        text: "Really " + Power.confirmLabel(page.pendingAction).toLowerCase() + "?"
                        color: Theme.onSurface
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(10.5)
                        wrapMode: Text.WordWrap
                    }
                    Button {
                        label: "Cancel"
                        primary: false
                        implicitHeight: 28
                        onClicked: page.pendingAction = ""
                    }
                    Button {
                        label: Power.confirmLabel(page.pendingAction)
                        destructive: true
                        implicitHeight: 28
                        onClicked: page.confirmAction()
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: Power.actions
                    delegate: Button {
                        required property var modelData
                        label: modelData.label
                        icon: modelData.icon
                        primary: false
                        destructive: modelData.id === "shutdown"
                        implicitHeight: 34
                        onClicked: page.requestAction(modelData.id)
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
    }
}
