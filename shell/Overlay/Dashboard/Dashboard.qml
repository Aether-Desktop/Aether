import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../../Aether"

// Control centre: clock, weather, calendar, media, live system telemetry
// and session quick actions. Every value is backed by a real service.
Item {
    id: root

    implicitWidth: 640
    implicitHeight: 704
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.leftMargin: 24
    anchors.topMargin: 64
    height: Math.min(parent.height - 88, root.implicitHeight)

    property date now: new Date()
    property int monthShift: 0

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    readonly property date monthDate: new Date(root.now.getFullYear(), root.now.getMonth() + root.monthShift, 1)
    readonly property int daysInMonth: new Date(root.monthDate.getFullYear(), root.monthDate.getMonth() + 1, 0).getDate()
    readonly property int firstWeekday: (root.monthDate.getDay() + 6) % 7
    readonly property var weekdayNames: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    function isToday(day) {
        const d = new Date(root.monthDate.getFullYear(), root.monthDate.getMonth(), day);
        const t = new Date();
        return d.getFullYear() === t.getFullYear() && d.getMonth() === t.getMonth() && d.getDate() === t.getDate();
    }

    function greeting() {
        const h = root.now.getHours();
        if (h < 5) return "Good night";
        if (h < 12) return "Good morning";
        if (h < 18) return "Good afternoon";
        return "Good evening";
    }

    function shortDay(dateString) {
        const d = new Date(String(dateString) + "T00:00:00");
        return isNaN(d.getTime()) ? "" : Qt.formatDateTime(d, "ddd");
    }

    function openSettings() {
        Quickshell.execDetached(["aether-settings"]);
        UiState.close();
    }

    function toggleNightLight() {
        Brightness.setNightLight(!Brightness.nightLight);
    }

    function toggleTheme() {
        Config.setTheme(Theme.isLight ? "aether-dark" : "aether-light");
    }

    Surface {
        anchors.fill: parent
        fill: Theme.glassHigh
        padding: 20
        radius: Theme.radiusLg

        ColumnLayout {
            anchors.fill: parent
            spacing: 14

            // ---------------- Header ----------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Column {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: root.greeting()
                        color: Theme.onSurface
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(22)
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: Qt.formatDateTime(root.now, "dddd, d MMMM yyyy")
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(12)
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: Qt.formatDateTime(root.now, Config.bar.clockSeconds ? "HH:mm:ss" : "HH:mm")
                    color: Theme.onSurface
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(28)
                    font.weight: Font.DemiBold
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 158
                spacing: 14

                // ---------------- Weather ----------------
                Surface {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusMd
                    fill: Theme.surfaceContainer
                    padding: 16
                    shadow: false

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            Icon { name: "weather-cloud"; size: 15; color: Theme.primary }
                            Text {
                                Layout.fillWidth: true
                                text: Weather.configured ? (Weather.place || "Weather") : "Weather"
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(11.5)
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                visible: Weather.configured
                                text: Weather.unitSuffix()
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(10)
                            }
                        }

                        // Configured and loaded
                        RowLayout {
                            visible: Weather.available
                            Layout.fillWidth: true
                            spacing: 12

                            Icon {
                                name: Weather.iconFor(Weather.code, Weather.isDay)
                                size: 44
                                color: Theme.primary
                            }
                            ColumnLayout {
                                spacing: 0
                                Text {
                                    text: Math.round(Weather.temperature) + "°"
                                    color: Theme.onSurface
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(34)
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: Weather.describe(Weather.code) + " · feels " + Math.round(Weather.feelsLike) + "°"
                                    color: Theme.onSurfaceVariant
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(11)
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        RowLayout {
                            visible: Weather.available && Weather.daily.length > 0
                            Layout.fillWidth: true
                            spacing: 10
                            Repeater {
                                model: Weather.daily.slice(0, 3)
                                delegate: ColumnLayout {
                                    required property var modelData
                                    spacing: 0
                                    Text {
                                        text: root.shortDay(modelData.date)
                                        color: Theme.onSurfaceVariant
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fs(9.5)
                                    }
                                    Text {
                                        text: Math.round(modelData.max) + "° / " + Math.round(modelData.min) + "°"
                                        color: Theme.onSurface
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fs(10.5)
                                    }
                                }
                            }
                        }

                        // Unconfigured / error state
                        ColumnLayout {
                            visible: !Weather.available
                            Layout.fillWidth: true
                            spacing: 4
                            Text {
                                Layout.fillWidth: true
                                text: Weather.configured ? (Weather.error || "Loading forecast…")
                                    : "Add your coordinates in Settings to see local weather."
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(11)
                                wrapMode: Text.WordWrap
                            }
                            Button {
                                label: Weather.configured ? "Retry" : "Open Settings"
                                icon: "settings"
                                implicitHeight: 30
                                primary: false
                                onClicked: Weather.configured ? Weather.refresh() : root.openSettings()
                            }
                        }
                    }
                }

                // ---------------- Battery / power ----------------
                Surface {
                    Layout.preferredWidth: 190
                    Layout.fillHeight: true
                    radius: Theme.radiusMd
                    fill: Theme.surfaceContainer
                    padding: 14
                    shadow: false

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 6
                        visible: System.hasBattery

                        RowLayout {
                            Layout.fillWidth: true
                            Icon { name: System.charging ? "power" : "battery"; size: 15; color: Theme.primary }
                            Text {
                                Layout.fillWidth: true
                                text: System.charging ? "Charging" : "Battery"
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(11.5)
                                font.weight: Font.DemiBold
                            }
                        }

                        ProgressRing {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 76
                            Layout.preferredHeight: 76
                            value: System.batteryLevel
                            lineWidth: 6
                            color: System.batteryLevel <= 0.15 && !System.charging ? Theme.error : Theme.primary
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: System.batteryPercent() + "%"
                            color: Theme.onSurface
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(20)
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: System.powerProfile === PowerProfile.PowerSaver ? "Power saver"
                                : System.powerProfile === PowerProfile.Performance ? "Performance" : "Balanced"
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(10)
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 6
                        visible: !System.hasBattery
                        RowLayout {
                            Layout.fillWidth: true
                            Icon { name: "power"; size: 15; color: Theme.primary }
                            Text {
                                Layout.fillWidth: true
                                text: "Session"
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(11.5)
                                font.weight: Font.DemiBold
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "No battery detected. Power profile: "
                                + (System.powerProfile === PowerProfile.PowerSaver ? "saver"
                                : System.powerProfile === PowerProfile.Performance ? "performance" : "balanced")
                            color: Theme.onSurface
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(12)
                            wrapMode: Text.WordWrap
                        }
                        Item { Layout.fillHeight: true }
                        Button {
                            Layout.fillWidth: true
                            label: "Power menu"
                            icon: "power"
                            primary: false
                            implicitHeight: 32
                            onClicked: UiState.open("power")
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14

                // ---------------- Calendar ----------------
                Surface {
                    Layout.preferredWidth: 300
                    Layout.fillHeight: true
                    radius: Theme.radiusMd
                    fill: Theme.surfaceContainer
                    padding: 14
                    shadow: false

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: Qt.formatDateTime(root.monthDate, "MMMM yyyy")
                                color: Theme.onSurface
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(13)
                                font.weight: Font.DemiBold
                            }
                            IconButton {
                                icon: "chevron-left"; iconSize: 14; buttonSize: 26
                                accessibleName: "Previous month"
                                onClicked: root.monthShift--
                            }
                            IconButton {
                                icon: "chevron-right"; iconSize: 14; buttonSize: 26
                                accessibleName: "Next month"
                                onClicked: root.monthShift++
                            }
                            IconButton {
                                icon: "calendar"; iconSize: 14; buttonSize: 26
                                accessibleName: "Current month"
                                onClicked: root.monthShift = 0
                            }
                        }

                        Grid {
                            Layout.fillWidth: true
                            columns: 7
                            rowSpacing: 2
                            columnSpacing: 2
                            Repeater {
                                model: root.weekdayNames
                                delegate: Text {
                                    required property string modelData
                                    width: (parent.width - 12) / 7
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData
                                    color: Theme.onSurfaceVariant
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(9.5)
                                    font.weight: Font.DemiBold
                                }
                            }
                            Repeater {
                                model: 42
                                delegate: Item {
                                    required property int index
                                    readonly property int day: index - root.firstWeekday + 1
                                    readonly property bool valid: day >= 1 && day <= root.daysInMonth
                                    readonly property bool today: valid && root.isToday(day)
                                    width: (parent.width - 12) / 7
                                    height: 22
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 22
                                        height: 22
                                        radius: 11
                                        color: parent.today ? Theme.primary : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: parent.parent.valid ? parent.parent.day : ""
                                            color: parent.parent.today ? Theme.onPrimary
                                                : (parent.parent.valid ? Theme.onSurface : "transparent")
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fs(10.5)
                                            font.weight: parent.parent.today ? Font.Bold : Font.Normal
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Icon { name: "calendar"; size: 12; color: Theme.onSurfaceVariant }
                            Text {
                                Layout.fillWidth: true
                                text: "Week " + Qt.formatDateTime(root.now, "ww") + " · "
                                    + (System.hasBattery ? "on battery " + System.batteryPercent() + "%" : "desktop session")
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(9.5)
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                // ---------------- Quick actions ----------------
                Surface {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusMd
                    fill: Theme.surfaceContainer
                    padding: 14
                    shadow: false

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8

                        Text {
                            text: "Quick actions"
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(11.5)
                            font.weight: Font.DemiBold
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 2
                            rowSpacing: 8
                            columnSpacing: 8

                            Repeater {
                                model: [
                                    { label: "Settings", icon: "settings", act: "settings" },
                                    { label: Brightness.nightLight ? "Night light on" : "Night light", icon: "nightlight", act: "night" },
                                    { label: Theme.isLight ? "Dark theme" : "Light theme", icon: Theme.isLight ? "moon" : "sun", act: "theme" },
                                    { label: "Lock", icon: "lock", act: "lock" }
                                ]
                                delegate: Item {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    implicitHeight: 52

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Theme.radiusSm
                                        color: actionHover.hovered ? Theme.hover : Theme.surfaceContainerHigh
                                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 7
                                            Icon {
                                                name: modelData.icon
                                                size: 16
                                                color: modelData.act === "night" && Brightness.nightLight ? Theme.primary : Theme.onSurface
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                            Text {
                                                text: modelData.label
                                                color: Theme.onSurface
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fs(11)
                                                elide: Text.ElideRight
                                                width: Math.min(implicitWidth, parent.parent.width - 52)
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }
                                    HoverHandler { id: actionHover; cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        acceptedButtons: Qt.LeftButton
                                        onTapped: {
                                            switch (modelData.act) {
                                            case "settings": root.openSettings(); break;
                                            case "night": root.toggleNightLight(); break;
                                            case "theme": root.toggleTheme(); break;
                                            case "lock": UiState.close(); Power.perform("lock"); break;
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            label: "Power menu"
                            icon: "power"
                            primary: false
                            implicitHeight: 30
                            onClicked: UiState.open("power")
                        }
                    }
                }
            }

            // ---------------- Media ----------------
            Surface {
                Layout.fillWidth: true
                Layout.preferredHeight: 88
                radius: Theme.radiusMd
                fill: Theme.surfaceContainer
                padding: 12
                shadow: false

                RowLayout {
                    anchors.fill: parent
                    spacing: 12
                    visible: System.hasMedia

                    Rectangle {
                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 56
                        radius: Theme.radiusSm
                        color: Theme.surfaceContainerHighest
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: System.trackArt
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: status === Image.Ready
                        }
                        Icon {
                            anchors.centerIn: parent
                            visible: System.trackArt.length === 0
                            name: "music"; size: 22; color: Theme.primary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Text {
                            Layout.fillWidth: true
                            text: System.trackTitle
                            color: Theme.onSurface
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(12.5)
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: System.trackArtist + (System.trackAlbum.length > 0 ? " · " + System.trackAlbum : "")
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(10.5)
                            elide: Text.ElideRight
                        }
                        Slider {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 22
                            from: 0
                            to: Math.max(1, System.trackLength)
                            value: System.trackPosition
                            enabled: System.canSeek
                            onMoved: (v) => System.seekTo(v)
                        }
                    }

                    Row {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2
                        IconButton {
                            icon: "prev"; iconSize: 16; buttonSize: 32
                            accessibleName: "Previous track"
                            onClicked: System.previous()
                        }
                        IconButton {
                            icon: System.playing ? "pause" : "play"
                            iconSize: 18; buttonSize: 38; active: System.playing
                            accessibleName: System.playing ? "Pause" : "Play"
                            onClicked: System.togglePlay()
                        }
                        IconButton {
                            icon: "next"; iconSize: 16; buttonSize: 32
                            accessibleName: "Next track"
                            onClicked: System.next()
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 10
                    visible: !System.hasMedia
                    Icon { name: "music"; size: 20; color: Theme.onSurfaceVariant }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: "Nothing playing"
                            color: Theme.onSurface
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(12.5)
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: "Start a player that supports MPRIS and it will appear here."
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(10.5)
                        }
                    }
                }
            }

            // ---------------- Live telemetry ----------------
            Surface {
                Layout.fillWidth: true
                Layout.preferredHeight: 122
                radius: Theme.radiusMd
                fill: Theme.surfaceContainer
                padding: 12
                shadow: false

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: "System"
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(11.5)
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: Stats.available ? "live · " + Math.round(Stats.uptime / 3600) + "h uptime" : "collector unavailable"
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(9.5)
                        }
                    }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 24
                        rowSpacing: 0
                        Meter {
                            Layout.fillWidth: true
                            label: "CPU"
                            icon: "cpu"
                            value: Stats.cpu.percent / 100
                            valueText: Math.round(Stats.cpu.percent) + "%"
                        }
                        Meter {
                            Layout.fillWidth: true
                            label: "Memory"
                            icon: "memory"
                            value: Stats.memory.percent / 100
                            valueText: Math.round(Stats.memory.percent) + "%"
                        }
                        Meter {
                            Layout.fillWidth: true
                            label: "Disk"
                            icon: "disk"
                            value: Stats.disk.percent / 100
                            valueText: Math.round(Stats.disk.percent) + "%"
                        }
                        Meter {
                            Layout.fillWidth: true
                            label: "CPU temp"
                            icon: "thermometer"
                            value: Stats.cpuTemp / 100
                            valueText: Stats.cpuTemp > 0 ? Math.round(Stats.cpuTemp) + "°C" : "n/a"
                            accent: Stats.cpuTemp >= 85 ? Theme.error : (Stats.cpuTemp >= 70 ? Theme.warning : Theme.primary)
                        }
                    }
                }
            }
        }
    }
}
