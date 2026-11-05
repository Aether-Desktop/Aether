pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Polls the AETHER stats helper (Python, stdlib only) and exposes parsed values.
// CPU/GPU/memory/disk/network/temperature are real reads of /proc and /sys.
QtObject {
    id: root

    readonly property int intervalMs: 2500

    property var snapshot: ({
        cpu: { percent: 0, cores: 0, load: [0, 0, 0] },
        memory: { total: 0, used: 0, percent: 0 },
        disk: { total: 0, used: 0, percent: 0 },
        network: { rxRate: 0, txRate: 0, rx: 0, tx: 0 },
        temperatures: [],
        gpu: null,
        battery: null,
        uptime: 0
    })
    property bool available: false
    property string lastError: ""

    readonly property var cpu: root.snapshot.cpu || ({ percent: 0, cores: 0, load: [0, 0, 0] })
    readonly property var memory: root.snapshot.memory || ({ total: 0, used: 0, percent: 0 })
    readonly property var disk: root.snapshot.disk || ({ total: 0, used: 0, percent: 0 })
    readonly property var network: root.snapshot.network || ({ rxRate: 0, txRate: 0 })
    readonly property var gpu: root.snapshot.gpu || null
    readonly property var temperatures: root.snapshot.temperatures || []
    readonly property real cpuTemp: {
        const ts = root.temperatures;
        let best = 0;
        for (let i = 0; i < ts.length; i++) {
            const n = (ts[i].name || "").toLowerCase();
            if (n.indexOf("package") !== -1 || n.indexOf("tctl") !== -1 || n.indexOf("cpu") !== -1)
                return Math.max(0, ts[i].value);
            best = Math.max(best, ts[i].value || 0);
        }
        return best;
    }
    readonly property real uptime: root.snapshot.uptime || 0

    function refresh() { if (!statsProcess.running) statsProcess.running = true; }

    property StdioCollector statsOut: StdioCollector {
        waitForEnd: true
        onStreamFinished: {
            const text = statsOut.text;
            if (!text || text.length === 0) return;
            try {
                root.snapshot = JSON.parse(text);
                root.available = true;
                root.lastError = "";
            } catch (e) {
                root.lastError = String(e);
                console.warn("AETHER: could not parse stats output:", e);
            }
        }
    }

    property Process statsProcess: Process {
        command: ["python3", Config.installRoot + "/scripts/aether-stats"]
        stdout: root.statsOut
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (text.length > 0) console.warn("AETHER stats:", text)
        }
        onExited: (code, status) => {
            if (code !== 0) root.lastError = "collector exited with code " + code;
        }
    }

    property Timer poll: Timer {
        interval: root.intervalMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
