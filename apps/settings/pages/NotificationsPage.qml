import QtQuick
import QtQuick.Layouts
import Quickshell
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
            title: "Delivery"
            Layout.fillWidth: true

            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Do not disturb"
                description: "Keep collecting history but suppress popups."
                checked: Config.notifications.doNotDisturb === true
                onToggled: (value) => Notify.setDnd(value)
            }
            SettingsSliderRow {
                Layout.fillWidth: true
                title: "Popup duration"
                value: Config.notifications.timeout || 6000
                from: 2000
                to: 15000
                stepSize: 500
                valueText: (Number(Config.notifications.timeout || 6000) / 1000).toFixed(1) + " s"
                onMoved: (v) => Config.set("notifications.timeout", Math.round(v))
            }
            SettingsChoiceRow {
                Layout.fillWidth: true
                title: "Popup position"
                options: [{ label: "Top right", value: "top-right" }, { label: "Bottom right", value: "bottom-right" }]
                current: Config.notifications.position || "top-right"
                onChosen: (value) => Config.set("notifications.position", value)
            }
        }

        SettingsCard {
            title: "History"
            Layout.fillWidth: true

            SettingsSliderRow {
                Layout.fillWidth: true
                title: "History size"
                description: "Older notifications are dismissed once the limit is reached."
                value: Config.notifications.historySize || 100
                from: 10
                to: 200
                stepSize: 10
                valueText: Math.round(Config.notifications.historySize || 100) + " items"
                onMoved: (v) => Config.set("notifications.historySize", Math.round(v))
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Group notifications by application"
                description: "A newer notification from the same application replaces its open popup."
                checked: Config.notifications.grouping === true
                onToggled: (value) => Config.set("notifications.grouping", value)
            }
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Currently holding " + Notify.count + " notifications."
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(10)
                }
                Button {
                    label: "Send test"
                    icon: "bell"
                    primary: false
                    implicitHeight: 30
                    onClicked: Quickshell.execDetached(["notify-send", "-a", "AETHER", "AETHER notifications", "This is a test notification from Settings."])
                }
                Button {
                    label: "Clear all"
                    icon: "trash"
                    primary: false
                    implicitHeight: 30
                    enabled: Notify.count > 0
                    onClicked: Notify.dismissAll()
                }
            }
        }

        SettingsCard {
            title: "Content"
            Layout.fillWidth: true

            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Show body text"
                checked: Config.notifications.showBody !== false
                onToggled: (value) => Config.set("notifications.showBody", value)
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Show attached images"
                checked: Config.notifications.showImage !== false
                onToggled: (value) => Config.set("notifications.showImage", value)
            }
            Text {
                Layout.fillWidth: true
                text: "Notification actions supplied by applications are always shown when present. Inline replies are advertised but require a capable client."
                color: Theme.onSurfaceVariant
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fs(9.5)
                wrapMode: Text.WordWrap
            }
        }
    }
}
