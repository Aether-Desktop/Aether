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
            title: "Weather"
            description: "AETHER uses Open-Meteo with the coordinates you provide. It never geolocates you by IP address."
            Layout.fillWidth: true

            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Show weather"
                checked: Config.dashboard.weather.enabled !== false
                onToggled: (value) => Config.set("dashboard.weather.enabled", value)
            }
            SettingsTextField {
                Layout.fillWidth: true
                title: "Place name"
                description: "Shown on the dashboard. Optional."
                value: Config.dashboard.weather.place || ""
                placeholder: "Berlin"
                onEdited: (value) => Config.set("dashboard.weather.place", value.trim())
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                SettingsTextField {
                    Layout.fillWidth: true
                    title: "Latitude"
                    value: Config.dashboard.weather.latitude !== null
                        ? String(Config.dashboard.weather.latitude) : ""
                    placeholder: "52.5200"
                    numeric: true
                    onEdited: (value) => page.setCoordinate("latitude", value, -90, 90)
                }
                SettingsTextField {
                    Layout.fillWidth: true
                    title: "Longitude"
                    value: Config.dashboard.weather.longitude !== null
                        ? String(Config.dashboard.weather.longitude) : ""
                    placeholder: "13.4050"
                    numeric: true
                    onEdited: (value) => page.setCoordinate("longitude", value, -180, 180)
                }
            }
            SettingsChoiceRow {
                Layout.fillWidth: true
                title: "Units"
                options: [{ label: "Metric (°C, km/h)", value: "metric" }, { label: "Imperial (°F, mph)", value: "imperial" }]
                current: Config.dashboard.weather.units || "metric"
                onChosen: (value) => Config.set("dashboard.weather.units", value)
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: Weather.configured
                        ? (Weather.available
                            ? "Last update: " + (Weather.lastUpdated > 0 ? Qt.formatDateTime(new Date(Weather.lastUpdated), "HH:mm") : "pending")
                            : (Weather.error || "Waiting for data"))
                        : "Set both coordinates to enable weather."
                    color: Weather.error.length > 0 ? Theme.error : Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(9.5)
                    wrapMode: Text.WordWrap
                }
                Button {
                    label: "Refresh"
                    icon: "refresh"
                    primary: false
                    implicitHeight: 30
                    enabled: Weather.configured
                    onClicked: Weather.refresh()
                }
            }
        }

        SettingsCard {
            title: "Dashboard cards"
            Layout.fillWidth: true

            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Calendar"
                checked: Config.dashboard.calendar !== false
                onToggled: (value) => Config.set("dashboard.calendar", value)
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Media controls"
                checked: Config.dashboard.media !== false
                onToggled: (value) => Config.set("dashboard.media", value)
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "System telemetry"
                checked: Config.dashboard.stats !== false
                onToggled: (value) => Config.set("dashboard.stats", value)
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Quick actions"
                checked: Config.dashboard.quickActions !== false
                onToggled: (value) => Config.set("dashboard.quickActions", value)
            }
        }

        SettingsCard {
            title: "Launcher"
            Layout.fillWidth: true

            SettingsSliderRow {
                Layout.fillWidth: true
                title: "Maximum search results"
                value: Config.launcher.maxResults || 8
                from: 4
                to: 16
                stepSize: 1
                valueText: Math.round(Config.launcher.maxResults || 8)
                onMoved: (v) => Config.set("launcher.maxResults", Math.round(v))
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Show favourites and recents first"
                checked: Config.launcher.showFavorites !== false
                onToggled: (value) => Config.set("launcher.showFavorites", value)
            }
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Favourite applications: " + (Config.launcher.favorites || []).length
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(10)
                }
                Button {
                    label: "Clear recent"
                    icon: "trash"
                    primary: false
                    implicitHeight: 30
                    onClicked: Config.set("launcher.recent", [])
                }
            }
        }
    }

    function setCoordinate(field, text, min, max) {
        const value = String(text || "").trim();
        if (value.length === 0) {
            Config.set("dashboard.weather." + field, null);
            return;
        }
        const n = Number(value);
        if (!isFinite(n) || n < min || n > max) {
            console.warn("AETHER: invalid " + field + ":", text);
            return;
        }
        Config.set("dashboard.weather." + field, n);
    }
}
