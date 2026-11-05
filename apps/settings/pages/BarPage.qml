import QtQuick
import QtQuick.Layouts
import "../../../shell/Aether"
import "../components"

Item {
    id: page

    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 14

        SettingsCard {
            title: "Placement"
            description: "Floating bars sit below the monitor edge with a margin. Docked bars span the full edge."
            Layout.fillWidth: true

            SettingsChoiceRow {
                Layout.fillWidth: true
                title: "Position"
                options: [{ label: "Top", value: "top" }, { label: "Bottom", value: "bottom" }]
                current: Config.bar.position || "top"
                onChosen: (value) => Config.set("bar.position", value)
            }
            SettingsChoiceRow {
                Layout.fillWidth: true
                title: "Mode"
                options: [{ label: "Floating", value: "floating" }, { label: "Docked", value: "docked" }]
                current: Config.bar.mode || "floating"
                onChosen: (value) => Config.set("bar.mode", value)
            }
            SettingsSliderRow {
                Layout.fillWidth: true
                title: "Bar height"
                value: Config.bar.height || 44
                from: 34
                to: 72
                stepSize: 1
                valueText: Math.round(Config.bar.height || 44) + " px"
                onMoved: (v) => Config.set("bar.height", Math.round(v))
            }
            SettingsSliderRow {
                Layout.fillWidth: true
                title: "Outer margin"
                visible: (Config.bar.mode || "floating") === "floating"
                value: Config.bar.margin || 8
                from: 0
                to: 24
                stepSize: 1
                valueText: Math.round(Config.bar.margin || 8) + " px"
                onMoved: (v) => Config.set("bar.margin", Math.round(v))
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Reserve screen space"
                description: "Ask Hyprland to keep windows out of the bar area (exclusive zone)."
                checked: Config.bar.exclusive === true
                onToggled: (value) => Config.set("bar.exclusive", value)
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Auto-hide"
                description: "Collapse to a five-pixel reveal strip and expand on hover."
                checked: Config.bar.autoHide === true
                onToggled: (value) => Config.set("bar.autoHide", value)
            }
        }

        SettingsCard {
            title: "Clock"
            Layout.fillWidth: true

            SettingsTextField {
                Layout.fillWidth: true
                title: "Time format"
                description: "Qt format string, for example HH:mm or hh:mm AP."
                value: Config.bar.clockFormat || "HH:mm"
                placeholder: "HH:mm"
                onEdited: (value) => Config.set("bar.clockFormat", value.length > 0 ? value : "HH:mm")
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Show seconds"
                checked: Config.bar.clockSeconds === true
                onToggled: (value) => Config.set("bar.clockSeconds", value)
            }
            SettingsSliderRow {
                Layout.fillWidth: true
                title: "Workspace count"
                description: "Number of workspace indicators shown on wide bars."
                value: Config.bar.workspaceCount || 6
                from: 3
                to: 12
                stepSize: 1
                valueText: Math.round(Config.bar.workspaceCount || 6)
                onMoved: (v) => Config.set("bar.workspaceCount", Math.round(v))
            }
        }

        SettingsCard {
            title: "Visible items"
            description: "Every item is live; hiding one does not stop the underlying service."
            Layout.fillWidth: true

            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Workspaces"
                checked: Config.bar.showWorkspaces !== false
                onToggled: (value) => Config.set("bar.showWorkspaces", value)
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Active window title"
                checked: Config.bar.showActiveWindow !== false
                onToggled: (value) => Config.set("bar.showActiveWindow", value)
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Now playing"
                checked: Config.bar.showMedia !== false
                onToggled: (value) => Config.set("bar.showMedia", value)
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "System tray"
                checked: Config.bar.showTray !== false
                onToggled: (value) => Config.set("bar.showTray", value)
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Battery"
                checked: Config.bar.showBattery !== false
                onToggled: (value) => Config.set("bar.showBattery", value)
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Network"
                checked: Config.bar.showNetwork !== false
                onToggled: (value) => Config.set("bar.showNetwork", value)
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Bluetooth"
                checked: Config.bar.showBluetooth !== false
                onToggled: (value) => Config.set("bar.showBluetooth", value)
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Volume"
                checked: Config.bar.showVolume !== false
                onToggled: (value) => Config.set("bar.showVolume", value)
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Notification bell"
                checked: Config.bar.showNotifications !== false
                onToggled: (value) => Config.set("bar.showNotifications", value)
            }
        }

        SettingsCard {
            title: "Monitor filter"
            description: "Leave empty to show the bar on every monitor. Otherwise enter comma-separated monitor names."
            Layout.fillWidth: true

            SettingsTextField {
                Layout.fillWidth: true
                title: "Monitors"
                value: (Config.bar.monitors || []).join(", ")
                placeholder: "eDP-1, HDMI-A-1"
                onEdited: (value) => {
                    const list = value.split(",").map((x) => x.trim()).filter((x) => x.length > 0);
                    Config.set("bar.monitors", list);
                }
            }
        }
    }
}
