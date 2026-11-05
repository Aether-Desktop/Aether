pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "Util.js" as Util

// Weather via Open-Meteo (no API key, no account, no tracking identifier).
// Location is explicitly configured in Settings; we do not geolocate by IP.
QtObject {
    id: root

    readonly property var cfg: Config.dashboard.weather || ({})
    readonly property real latitude: root.cfg.latitude !== null ? Number(root.cfg.latitude) : NaN
    readonly property real longitude: root.cfg.longitude !== null ? Number(root.cfg.longitude) : NaN
    readonly property bool configured: isFinite(root.latitude) && isFinite(root.longitude)
        && root.latitude >= -90 && root.latitude <= 90
        && root.longitude >= -180 && root.longitude <= 180
    readonly property string place: root.cfg.place || ""

    property var current: null
    property var daily: []
    property bool loading: false
    property string error: ""
    property double lastUpdated: 0

    readonly property bool available: root.current !== null
    readonly property real temperature: root.current ? root.current.temperature : 0
    readonly property real feelsLike: root.current ? root.current.feelsLike : 0
    readonly property int humidity: root.current ? root.current.humidity : 0
    readonly property real wind: root.current ? root.current.wind : 0
    readonly property int code: root.current ? root.current.code : -1
    readonly property bool isDay: root.current ? root.current.isDay : true

    function units() { return root.cfg.units === "imperial" ? "imperial" : "metric"; }
    function unitSuffix() { return root.units() === "imperial" ? "°F" : "°C"; }
    function windUnit() { return root.units() === "imperial" ? "mph" : "km/h"; }

    function describe(code) {
        if (code === 0) return "Clear";
        if (code === 1) return "Mostly clear";
        if (code === 2) return "Partly cloudy";
        if (code === 3) return "Overcast";
        if (code === 45 || code === 48) return "Fog";
        if (code >= 51 && code <= 57) return "Drizzle";
        if (code >= 61 && code <= 67) return "Rain";
        if (code >= 71 && code <= 77) return "Snow";
        if (code >= 80 && code <= 82) return "Showers";
        if (code === 85 || code === 86) return "Snow showers";
        if (code >= 95) return "Thunderstorm";
        return "Unknown";
    }

    function iconFor(code, day) {
        if (code === 0 || code === 1) return day ? "weather-sun" : "night";
        if (code === 2) return "weather-cloud";
        if (code === 3) return "weather-cloud";
        if (code === 45 || code === 48) return "weather-fog";
        if (code >= 51 && code <= 67) return "weather-rain";
        if (code >= 71 && code <= 77) return "weather-snow";
        if (code >= 80 && code <= 82) return "weather-rain";
        if (code === 85 || code === 86) return "weather-snow";
        if (code >= 95) return "weather-storm";
        return "weather-cloud";
    }

    function refresh() {
        if (!root.configured) {
            root.error = "Set a location in Settings → Dashboard";
            return;
        }
        if (request.running) return;
        root.loading = true;
        const temp = root.units() === "imperial" ? "fahrenheit" : "celsius";
        const wind = root.units() === "imperial" ? "mph" : "kmh";
        request.command = [
            "curl", "-fsS", "--max-time", "12", "--retry", "1",
            "https://api.open-meteo.com/v1/forecast"
                + "?latitude=" + root.latitude.toFixed(4)
                + "&longitude=" + root.longitude.toFixed(4)
                + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m"
                + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
                + "&timezone=auto&forecast_days=5"
                + "&temperature_unit=" + temp + "&wind_speed_unit=" + wind
        ];
        request.running = true;
    }

    property StdioCollector response: StdioCollector {
        waitForEnd: true
        onStreamFinished: {
            root.loading = false;
            if (response.text.length === 0) return;
            try {
                const doc = JSON.parse(response.text);
                if (!doc.current) throw new Error("missing current conditions");
                root.current = {
                    temperature: doc.current.temperature_2m,
                    feelsLike: doc.current.apparent_temperature,
                    humidity: doc.current.relative_humidity_2m,
                    wind: doc.current.wind_speed_10m,
                    code: doc.current.weather_code,
                    isDay: doc.current.is_day === 1
                };
                const d = doc.daily || {};
                const dates = d.time || [];
                root.daily = [];
                for (let i = 0; i < dates.length && i < 5; i++) {
                    root.daily.push({
                        date: dates[i],
                        code: (d.weather_code || [])[i],
                        max: (d.temperature_2m_max || [])[i],
                        min: (d.temperature_2m_min || [])[i]
                    });
                }
                root.error = "";
                root.lastUpdated = Date.now();
            } catch (e) {
                root.error = "Weather data unavailable";
                console.warn("AETHER weather:", e);
            }
        }
    }

    property Process request: Process {
        stdout: root.response
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (text.length > 0) root.error = "Weather request failed"
        }
        onExited: (code, status) => {
            root.loading = false;
            if (code !== 0 && root.error.length === 0) root.error = "Weather request failed";
        }
    }

    property Timer poll: Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    onConfiguredChanged: if (root.configured) root.refresh()
    Component.onCompleted: Qt.callLater(root.refresh)
}
