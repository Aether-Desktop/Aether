import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../../../shell/Aether"
import "../components"

Item {
    id: page

    implicitHeight: col.implicitHeight

    property string hint: ""
    property string previewText: ""
    property bool previewFailed: false
    property bool running: false

    readonly property var monitors: Hyprland.monitors ? Hyprland.monitors.values : []

    function run(args) {
        if (page.running) return;
        page.hint = "";
        page.previewFailed = false;
        page.running = true;
        const command = ["aether-hyprland"].concat(args);
        runner.command = command;
        runner.running = true;
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 14

        SettingsCard {
            title: "Monitors"
            description: "Live Hyprland IPC data. Configure monitor modes, scale and positions in your Hyprland config; AETHER only reads them here."
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: page.monitors
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: Theme.radiusSm
                        color: modelData.focused ? Theme.selected : Theme.surfaceContainerHigh

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10
                            Icon {
                                name: "monitor"
                                size: 16
                                color: modelData.focused ? Theme.primary : Theme.onSurfaceVariant
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    Layout.fillWidth: true
                                    text: (modelData.name || "Monitor")
                                        + (modelData.description ? " · " + modelData.description : "")
                                    color: Theme.onSurface
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(11.5)
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.width + "×" + modelData.height
                                        + " at " + Number(modelData.scale).toFixed(2) + "×"
                                        + " · position " + modelData.x + "," + modelData.y
                                    color: Theme.onSurfaceVariant
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(9.5)
                                    elide: Text.ElideRight
                                }
                            }
                            Text {
                                visible: modelData.focused
                                text: "Focused"
                                color: Theme.primary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(9)
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: page.monitors.length === 0
                    text: "No monitors reported. Is AETHER running inside a Hyprland session?"
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(10)
                    wrapMode: Text.WordWrap
                }
            }
        }

        SettingsCard {
            title: "Compositor integration"
            description: "AETHER can generate a self-contained Hyprland include. It never edits your main config silently."
            Layout.fillWidth: true

            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Manage AETHER Hyprland settings"
                description: "When enabled, the installer and aether-hyprland may write the generated include, always after a timestamped backup."
                checked: Config.hyprland.manageConfig === true
                onToggled: (value) => Config.set("hyprland.manageConfig", value)
            }

            SettingsSliderRow {
                Layout.fillWidth: true
                title: "Inner gaps"
                value: Config.hyprland.gapsIn || 5
                from: 0
                to: 24
                stepSize: 1
                valueText: Math.round(Config.hyprland.gapsIn || 5) + " px"
                onMoved: (v) => Config.set("hyprland.gapsIn", Math.round(v))
            }
            SettingsSliderRow {
                Layout.fillWidth: true
                title: "Outer gaps"
                value: Config.hyprland.gapsOut || 12
                from: 0
                to: 40
                stepSize: 1
                valueText: Math.round(Config.hyprland.gapsOut || 12) + " px"
                onMoved: (v) => Config.set("hyprland.gapsOut", Math.round(v))
            }
            SettingsSliderRow {
                Layout.fillWidth: true
                title: "Border size"
                value: Config.hyprland.borderSize || 2
                from: 0
                to: 6
                stepSize: 1
                valueText: Math.round(Config.hyprland.borderSize || 2) + " px"
                onMoved: (v) => Config.set("hyprland.borderSize", Math.round(v))
            }
            SettingsSliderRow {
                Layout.fillWidth: true
                title: "Corner rounding"
                value: Config.hyprland.rounding || 16
                from: 0
                to: 32
                stepSize: 1
                valueText: Math.round(Config.hyprland.rounding || 16) + " px"
                onMoved: (v) => Config.set("hyprland.rounding", Math.round(v))
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Blur"
                checked: Config.hyprland.blur === true
                onToggled: (value) => Config.set("hyprland.blur", value)
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Shadows"
                checked: Config.hyprland.shadows === true
                onToggled: (value) => Config.set("hyprland.shadows", value)
            }
            SettingsChoiceRow {
                Layout.fillWidth: true
                title: "Animation preset"
                options: [
                    { label: "AETHER", value: "aether" },
                    { label: "Snappy", value: "snappy" },
                    { label: "Reduced", value: "reduced" }
                ]
                current: Config.hyprland.animationPreset || "aether"
                onChosen: (value) => Config.set("hyprland.animationPreset", value)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: page.hint.length > 0
                        ? page.hint
                        : "The include is written to ~/.config/hypr/aether/generated.conf."
                    color: page.previewFailed ? Theme.error : Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(9.5)
                    wrapMode: Text.WordWrap
                }
                Button {
                    label: page.running ? "Working…" : "Preview"
                    icon: "eye"
                    primary: false
                    implicitHeight: 30
                    enabled: !page.running
                    onClicked: page.run(["--print"])
                }
                Button {
                    label: "Write include"
                    icon: "save"
                    implicitHeight: 30
                    enabled: !page.running
                    onClicked: page.run(["--apply"])
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: page.previewText.length > 0
                Layout.preferredHeight: 220
                radius: Theme.radiusSm
                color: Theme.surfaceContainerHighest
                clip: true

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 1
                    contentWidth: preview.implicitWidth
                    contentHeight: preview.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    TextArea {
                        id: preview
                        text: page.previewText
                        readOnly: true
                        selectByMouse: true
                        wrapMode: TextArea.NoWrap
                        color: Theme.onSurface
                        selectionColor: Theme.primary
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fs(9.5)
                        background: null
                        padding: 10
                    }
                }
            }
        }

        SettingsCard {
            title: "Reload"
            description: "Ask Hyprland to reload its configuration after writing the include."
            Layout.fillWidth: true

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: "Reloading applies compositor changes immediately. AETHER UI settings apply without a reload."
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(9.5)
                    wrapMode: Text.WordWrap
                }
                Button {
                    label: "Reload Hyprland"
                    icon: "refresh"
                    primary: false
                    implicitHeight: 30
                    onClicked: Hyprland.dispatch("reload")
                }
                Button {
                    label: "Reload AETHER"
                    icon: "refresh"
                    primary: false
                    implicitHeight: 30
                    onClicked: Quickshell.reload(false)
                }
            }
        }
    }

    property string rawOutput: ""
    property string rawError: ""

    property StdioCollector runOutput: StdioCollector {
        waitForEnd: true
        onStreamFinished: page.rawOutput = runOutput.text
    }

    property StdioCollector errorOutput: StdioCollector {
        waitForEnd: true
        onStreamFinished: page.rawError = errorOutput.text
    }

    property Process runner: Process {
        property var lastCommand: []
        command: []
        stdout: page.runOutput
        stderr: page.errorOutput
        onStarted: runner.lastCommand = command
        onExited: (code, status) => {
            page.running = false;
            const text = page.rawOutput.trim();
            const err = page.rawError.trim();
            const isPreview = runner.lastCommand.indexOf("--print") !== -1;
            if (code === 0) {
                page.hint = isPreview ? "Preview generated." : "Include written successfully.";
                if (isPreview) page.previewText = text;
                page.previewFailed = false;
            } else {
                page.previewFailed = true;
                if (err.length > 0) page.previewText = err;
                page.hint = err.length > 0
                    ? err.split("\n")[0]
                    : "aether-hyprland exited with code " + code + ".";
            }
        }
    }
}
