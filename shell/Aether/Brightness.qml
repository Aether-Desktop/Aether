pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "Util.js" as Util

// Backlight control through brightnessctl (the portable, permission-correct route).
// Value is 0..1. If brightnessctl is absent, `available` stays false and the UI
// explains the dependency instead of pretending to work.
QtObject {
    id: root

    property real value: 0.5
    property int max: 0
    property bool available: false
    property bool probed: false
    property bool nightLight: false
    property int nightLightTemperature: 4000
    property bool nightLightAvailable: false

    property StdioCollector infoOut: StdioCollector {
        waitForEnd: true
        onStreamFinished: {
            const text = infoOut.text.trim();
            if (!text) return;
            // brightnessctl -m: device,class,current,percent,max
            const parts = text.split(",");
            if (parts.length < 5) return;
            const pct = parseInt(parts[3], 10);
            if (!isNaN(pct)) root.value = Util.clamp(pct / 100, 0, 1);
            root.max = parseInt(parts[4], 10) || 0;
            root.available = true;
            root.probed = true;
        }
    }

    property Process probe: Process {
        command: ["brightnessctl", "-m"]
        stdout: root.infoOut
        stderr: StdioCollector { waitForEnd: true }
        onExited: (code, status) => {
            root.probed = true;
            if (code !== 0) root.available = false;
        }
    }

    property Process setter: Process {
        stdout: StdioCollector { waitForEnd: true }
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (text.length > 0) console.warn("AETHER brightness:", text)
        }
    }

    function refresh() {
        if (probe.running) return;
        probe.running = true;
    }

    function set(v) {
        root.value = Util.clamp(v, 0.01, 1);
        if (!root.available) return;
        setter.command = ["brightnessctl", "-q", "set", Math.round(root.value * 100) + "%"];
        setter.running = true;
    }

    function adjust(delta) {
        root.set(root.value + delta);
    }

    // Night light uses hyprsunset when present. We start/stop it explicitly so it
    // never lingers after the toggle is off.
    property Process nightLightProcess: Process {
        command: ["hyprsunset", "-t", String(root.nightLightTemperature)]
        onExited: (code, status) => {
            if (root.nightLight && code !== 0) {
                root.nightLight = false;
                root.nightLightAvailable = false;
            }
        }
    }

    function toggleNightLight() {
        root.setNightLight(!root.nightLight);
    }

    function setNightLight(enabled) {
        root.nightLight = enabled;
        Config.set("appearance.nightLight", enabled);
        if (enabled) {
            nightLightProcess.command = ["hyprsunset", "-t", String(root.nightLightTemperature)];
            nightLightProcess.running = true;
            root.nightLightAvailable = true;
            UiState.showOsd("nightlight", "Night light", 1, true);
        } else {
            nightLightProcess.running = false;
            UiState.showOsd("nightlight", "Night light off", 0, true);
        }
    }

    function setNightLightTemperature(kelvin) {
        const value = Util.clamp(Math.round(kelvin), 2500, 6500);
        root.nightLightTemperature = value;
        Config.set("appearance.nightLightTemperature", value);
        // hyprsunset reads the temperature at start-up, so restart it when the
        // user is actively running night light.
        if (root.nightLight) {
            nightLightProcess.running = false;
            nightLightProcess.command = ["hyprsunset", "-t", String(value)];
            nightLightProcess.running = true;
        }
    }

    property Timer poll: Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: {
        root.nightLight = Config.appearance.nightLight === true;
        root.nightLightTemperature = Number(Config.appearance.nightLightTemperature) || 4000;
        if (root.nightLight) {
            nightLightProcess.command = ["hyprsunset", "-t", String(root.nightLightTemperature)];
            nightLightProcess.running = true;
        }
    }
}
