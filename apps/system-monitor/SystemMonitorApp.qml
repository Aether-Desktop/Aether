import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../shell/Aether"

Item {
    id: root

    property var cpuHistory: []
    property var memoryHistory: []
    property var processes: []
    property string processError: ""
    property bool processRunning: false

    function formatBytes(bytes) {
        const n = Number(bytes) || 0;
        if (n <= 0) return "0 B";
        const units = ["B", "KiB", "MiB", "GiB", "TiB"];
        let i = 0;
        let v = n;
        while (v >= 1024 && i < units.length - 1) { v /= 1024; i++; }
        return (v >= 100 ? Math.round(v) : v.toFixed(1)) + " " + units[i];
    }

    function formatRate(bytes) {
        return root.formatBytes(bytes) + "/s";
    }

    function formatUptime(seconds) {
        const total = Math.floor(Number(seconds) || 0);
        if (total <= 0) return "—";
        const days = Math.floor(total / 86400);
        const hours = Math.floor((total % 86400) / 3600);
        const mins = Math.floor((total % 3600) / 60);
        if (days > 0) return days + "d " + hours + "h " + mins + "m";
        if (hours > 0) return hours + "h " + mins + "m";
        return mins + "m";
    }

    function pushSample() {
        const cpu = root.cpuHistory.slice();
        cpu.push(Stats.available ? Stats.cpu.percent : 0);
        while (cpu.length > 80) cpu.shift();
        root.cpuHistory = cpu;

        const mem = root.memoryHistory.slice();
        mem.push(Stats.available ? Stats.memory.percent : 0);
        while (mem.length > 80) mem.shift();
        root.memoryHistory = mem;
    }

    function parseProcesses(text) {
        const out = [];
        const lines = String(text || "").split("\n");
        for (let i = 0; i < lines.length && out.length < 24; i++) {
            const m = lines[i].match(/^\s*(\d+)\s+(\S+)\s+([\d.]+)\s+([\d.]+)\s+(\d+)/);
            if (!m) continue;
            out.push({
                pid: Number(m[1]),
                name: m[2],
                cpu: Number(m[3]),
                memory: Number(m[4]),
                rss: Number(m[5]) * 1024
            });
        }
        root.processes = out;
        root.processError = out.length === 0 ? "No process data returned by ps." : "";
    }

    function refreshProcesses() {
        if (!processProbe.running) processProbe.running = true;
    }

    readonly property var hottestSensors: {
        const list = Stats.temperatures.slice();
        list.sort((a, b) => (b.value || 0) - (a.value || 0));
        return list.slice(0, 5);
    }

    Timer {
        interval: 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.pushSample()
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshProcesses()
    }

    property StdioCollector processOut: StdioCollector {
        waitForEnd: true
        onStreamFinished: root.parseProcesses(processOut.text)
    }

    property Process processProbe: Process {
        command: ["ps", "-eo", "pid=,comm=,pcpu=,pmem=,rss=", "--sort=-pcpu"]
        stdout: root.processOut
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (text.trim().length > 0) root.processError = text.trim()
        }
        onExited: (code, status) => {
            root.processRunning = false;
            if (code !== 0 && root.processError.length === 0)
                root.processError = "ps exited with code " + code;
        }
        onStarted: root.processRunning = true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ---------------- Header ----------------
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 76

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 26
                anchors.rightMargin: 26
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: "System Monitor"
                        color: Theme.onSurface
                        font.family: Theme.fontDisplay
                        font.pixelSize: Theme.fs(22)
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: System.hostname + " · up " + root.formatUptime(Stats.uptime)
                            + " · " + (Stats.available ? "live /proc samples" : "waiting for collector")
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(10)
                    }
                }

                Button {
                    label: "Refresh"
                    icon: "refresh"
                    primary: false
                    implicitHeight: 32
                    onClicked: {
                        Stats.refresh();
                        root.refreshProcesses();
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hairline }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: content.implicitHeight + 40
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: content
                x: 26
                y: 20
                width: parent.width - 52
                spacing: 14

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 14
                    rowSpacing: 14

                    // CPU
                    Surface {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 190
                        radius: Theme.radiusMd
                        fill: Theme.surfaceContainer
                        padding: 16
                        shadow: false

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Icon { name: "cpu"; size: 18; color: Theme.primary }
                                Text {
                                    Layout.fillWidth: true
                                    text: "Processor"
                                    color: Theme.onSurface
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(13)
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: Stats.cpu.cores + " threads"
                                    color: Theme.onSurfaceVariant
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(9.5)
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Text {
                                    text: Math.round(Stats.cpu.percent) + "%"
                                    color: Theme.onSurface
                                    font.family: Theme.fontDisplay
                                    font.pixelSize: Theme.fs(30)
                                    font.weight: Font.Bold
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Text {
                                        Layout.fillWidth: true
                                        text: "Load " + Number(Stats.cpu.load[0]).toFixed(2)
                                            + "  " + Number(Stats.cpu.load[1]).toFixed(2)
                                            + "  " + Number(Stats.cpu.load[2]).toFixed(2)
                                        color: Theme.onSurfaceVariant
                                        font.family: Theme.fontMono
                                        font.pixelSize: Theme.fs(9.5)
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: Stats.cpuTemp > 0
                                            ? "Package " + Math.round(Stats.cpuTemp) + "°C"
                                            : "No CPU temperature sensor"
                                        color: Theme.onSurfaceVariant
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fs(9.5)
                                    }
                                }
                            }

                            HistoryChart {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumHeight: 70
                                values: root.cpuHistory
                                stroke: Theme.primary
                                fill: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.14)
                            }
                        }
                    }

                    // Memory
                    Surface {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 190
                        radius: Theme.radiusMd
                        fill: Theme.surfaceContainer
                        padding: 16
                        shadow: false

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Icon { name: "memory"; size: 18; color: Theme.secondary }
                                Text {
                                    Layout.fillWidth: true
                                    text: "Memory"
                                    color: Theme.onSurface
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(13)
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: Math.round(Stats.memory.percent) + "%"
                                    color: Theme.onSurface
                                    font.family: Theme.fontDisplay
                                    font.pixelSize: Theme.fs(20)
                                    font.weight: Font.Bold
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.formatBytes(Stats.memory.used) + " used of "
                                    + root.formatBytes(Stats.memory.total)
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(10)
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 8
                                radius: 4
                                color: Theme.surfaceContainerHighest
                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, Stats.memory.percent / 100))
                                    height: parent.height
                                    radius: parent.radius
                                    color: Theme.secondary
                                    Behavior on width { NumberAnimation { duration: Theme.durationNormal } }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: Stats.memory.swapTotal > 0
                                text: "Swap " + root.formatBytes(Stats.memory.swapUsed)
                                    + " of " + root.formatBytes(Stats.memory.swapTotal)
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(9.5)
                            }

                            HistoryChart {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumHeight: 60
                                values: root.memoryHistory
                                stroke: Theme.secondary
                                fill: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.14)
                            }
                        }
                    }

                    // Disk
                    Surface {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        radius: Theme.radiusMd
                        fill: Theme.surfaceContainer
                        padding: 16
                        shadow: false

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Icon { name: "disk"; size: 18; color: Theme.tertiary }
                                Text {
                                    Layout.fillWidth: true
                                    text: "Root filesystem"
                                    color: Theme.onSurface
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(13)
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: Math.round(Stats.disk.percent) + "%"
                                    color: Theme.onSurface
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(15)
                                    font.weight: Font.DemiBold
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.formatBytes(Stats.disk.used) + " used · "
                                    + root.formatBytes(Stats.disk.free) + " free · "
                                    + root.formatBytes(Stats.disk.total) + " total"
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(10)
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 8
                                radius: 4
                                color: Theme.surfaceContainerHighest
                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, Stats.disk.percent / 100))
                                    height: parent.height
                                    radius: parent.radius
                                    color: Theme.tertiary
                                }
                            }
                            Item { Layout.fillHeight: true }
                        }
                    }

                    // Network
                    Surface {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        radius: Theme.radiusMd
                        fill: Theme.surfaceContainer
                        padding: 16
                        shadow: false

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Icon { name: "globe"; size: 18; color: Theme.success }
                                Text {
                                    Layout.fillWidth: true
                                    text: "Network"
                                    color: Theme.onSurface
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(13)
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: System.networkName.length > 0 ? System.networkName : "offline"
                                    color: Theme.onSurfaceVariant
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(9.5)
                                    elide: Text.ElideRight
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 24
                                ColumnLayout {
                                    spacing: 0
                                    Text {
                                        text: "DOWN"
                                        color: Theme.onSurfaceVariant
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fs(8.5)
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.8
                                    }
                                    Text {
                                        text: root.formatRate(Stats.network.rxRate)
                                        color: Theme.onSurface
                                        font.family: Theme.fontMono
                                        font.pixelSize: Theme.fs(15)
                                        font.weight: Font.DemiBold
                                    }
                                }
                                ColumnLayout {
                                    spacing: 0
                                    Text {
                                        text: "UP"
                                        color: Theme.onSurfaceVariant
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fs(8.5)
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.8
                                    }
                                    Text {
                                        text: root.formatRate(Stats.network.txRate)
                                        color: Theme.onSurface
                                        font.family: Theme.fontMono
                                        font.pixelSize: Theme.fs(15)
                                        font.weight: Font.DemiBold
                                    }
                                }
                                Item { Layout.fillWidth: true }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: "Totals: " + root.formatBytes(Stats.network.rx) + " received · "
                                    + root.formatBytes(Stats.network.tx) + " sent"
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(9.5)
                            }
                            Item { Layout.fillHeight: true }
                        }
                    }
                }

                // Sensors / GPU
                Surface {
                    Layout.fillWidth: true
                    visible: root.hottestSensors.length > 0 || Stats.gpu !== null
                    Layout.preferredHeight: visible ? 150 : 0
                    radius: Theme.radiusMd
                    fill: Theme.surfaceContainer
                    padding: 16
                    shadow: false

                    RowLayout {
                        anchors.fill: parent
                        spacing: 24

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Icon { name: "thermometer"; size: 16; color: Theme.warning }
                                Text {
                                    Layout.fillWidth: true
                                    text: "Sensors"
                                    color: Theme.onSurface
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(12)
                                    font.weight: Font.DemiBold
                                }
                            }
                            Repeater {
                                model: root.hottestSensors
                                delegate: RowLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        color: Theme.onSurfaceVariant
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fs(9.5)
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: Math.round(modelData.value) + "°C"
                                        color: modelData.value > 80 ? Theme.error
                                            : (modelData.value > 65 ? Theme.warning : Theme.onSurface)
                                        font.family: Theme.fontMono
                                        font.pixelSize: Theme.fs(9.5)
                                    }
                                }
                            }
                        }

                        Rectangle {
                            visible: Stats.gpu !== null
                            width: 1
                            Layout.fillHeight: true
                            color: Theme.hairline
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: Stats.gpu !== null
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Icon { name: "sparkles"; size: 16; color: Theme.primary }
                                Text {
                                    Layout.fillWidth: true
                                    text: Stats.gpu ? (Stats.gpu.name || "GPU") : "GPU"
                                    color: Theme.onSurface
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(12)
                                    font.weight: Font.DemiBold
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: Stats.gpu
                                    ? "Utilisation " + Math.round(Stats.gpu.utilization || 0) + "%"
                                        + (Stats.gpu.temperature ? " · " + Math.round(Stats.gpu.temperature) + "°C" : "")
                                    : ""
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(10)
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: Stats.gpu !== null && Stats.gpu.memoryTotal
                                text: Stats.gpu && Stats.gpu.memoryTotal
                                    ? "VRAM " + root.formatBytes(Stats.gpu.memoryUsed || 0)
                                        + " of " + root.formatBytes(Stats.gpu.memoryTotal)
                                    : ""
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(9.5)
                            }
                        }
                    }
                }

                // Processes
                Surface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 380
                    radius: Theme.radiusMd
                    fill: Theme.surfaceContainer
                    padding: 16
                    shadow: false

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Icon { name: "activity"; size: 16; color: Theme.primary }
                            Text {
                                Layout.fillWidth: true
                                text: "Top processes by CPU"
                                color: Theme.onSurface
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(12)
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: "ps · lifetime average"
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(9)
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.hairline
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text { Layout.preferredWidth: 70; text: "PID"; color: Theme.onSurfaceVariant; font.family: Theme.fontMono; font.pixelSize: Theme.fs(9) }
                            Text { Layout.fillWidth: true; text: "COMMAND"; color: Theme.onSurfaceVariant; font.family: Theme.fontFamily; font.pixelSize: Theme.fs(9); font.weight: Font.DemiBold }
                            Text { Layout.preferredWidth: 64; text: "CPU"; color: Theme.onSurfaceVariant; font.family: Theme.fontFamily; font.pixelSize: Theme.fs(9); horizontalAlignment: Text.AlignRight }
                            Text { Layout.preferredWidth: 64; text: "MEM"; color: Theme.onSurfaceVariant; font.family: Theme.fontFamily; font.pixelSize: Theme.fs(9); horizontalAlignment: Text.AlignRight }
                            Text { Layout.preferredWidth: 84; text: "RSS"; color: Theme.onSurfaceVariant; font.family: Theme.fontFamily; font.pixelSize: Theme.fs(9); horizontalAlignment: Text.AlignRight }
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: root.processes
                            spacing: 1
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            delegate: Item {
                                required property var modelData
                                width: ListView.view.width
                                height: 26
                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 8
                                    Text { Layout.preferredWidth: 70; text: modelData.pid; color: Theme.onSurfaceVariant; font.family: Theme.fontMono; font.pixelSize: Theme.fs(9.5) }
                                    Text { Layout.fillWidth: true; text: modelData.name; color: Theme.onSurface; font.family: Theme.fontMono; font.pixelSize: Theme.fs(9.5); elide: Text.ElideRight }
                                    Text { Layout.preferredWidth: 64; text: modelData.cpu.toFixed(1) + "%"; color: modelData.cpu > 20 ? Theme.primary : Theme.onSurface; font.family: Theme.fontMono; font.pixelSize: Theme.fs(9.5); horizontalAlignment: Text.AlignRight }
                                    Text { Layout.preferredWidth: 64; text: modelData.memory.toFixed(1) + "%"; color: Theme.onSurfaceVariant; font.family: Theme.fontMono; font.pixelSize: Theme.fs(9.5); horizontalAlignment: Text.AlignRight }
                                    Text { Layout.preferredWidth: 84; text: root.formatBytes(modelData.rss); color: Theme.onSurfaceVariant; font.family: Theme.fontMono; font.pixelSize: Theme.fs(9.5); horizontalAlignment: Text.AlignRight }
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: root.processError.length > 0
                            text: root.processError
                            color: Theme.error
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(9.5)
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
}
