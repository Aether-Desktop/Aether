import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../../shell/Aether"
import "../components"

Item {
    id: page

    implicitHeight: col.implicitHeight

    property string quickshellVersion: "checking…"
    property string hyprlandVersion: "checking…"
    property string copiedHint: ""

    function openUrl(url) {
        Quickshell.execDetached(["xdg-open", url]);
    }

    function diagnostics() {
        return [
            "AETHER " + Config.aetherVersion,
            "Quickshell: " + page.quickshellVersion,
            "Hyprland: " + page.hyprlandVersion,
            "Qt: " + Qt.application.version,
            "Session: " + (Quickshell.env("XDG_SESSION_TYPE") || "unknown"),
            "Desktop: " + (Quickshell.env("XDG_CURRENT_DESKTOP") || "unknown"),
            "Host: " + System.hostname,
            "Theme: " + Config.themeId,
            "Shell dir: " + Quickshell.shellDir,
            "Config: " + Config.configFile,
            "State: " + Config.stateDir,
            "Hyprland IPC: " + (Hyprland.requestSocketPath || "unavailable")
        ].join("\n");
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 14

        SettingsCard {
            Layout.fillWidth: true

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Rectangle {
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 72
                    radius: Theme.radiusMd
                    color: Theme.primaryContainer
                    Image {
                        anchors.fill: parent
                        anchors.margins: 13
                        source: Qt.resolvedUrl("../../../assets/branding/aether-mark.svg")
                        fillMode: Image.PreserveAspectFit
                        sourceSize.width: 96
                        sourceSize.height: 96
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "AETHER"
                        color: Theme.onSurface
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(24)
                        font.weight: Font.Bold
                        font.letterSpacing: 2.6
                    }
                    Text {
                        text: "Your desktop. Your atmosphere. Your AETHER."
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(11.5)
                    }
                    Text {
                        text: "Version " + Config.aetherVersion + " · MIT licensed"
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(9.5)
                    }
                }

                ColumnLayout {
                    spacing: 6
                    Button {
                        label: "Website"
                        icon: "globe"
                        primary: false
                        implicitHeight: 30
                        onClicked: page.openUrl(Config.websiteUrl)
                    }
                    Button {
                        label: "Source"
                        icon: "github"
                        primary: false
                        implicitHeight: 30
                        onClicked: page.openUrl(Config.repositoryUrl)
                    }
                }
            }
        }

        SettingsCard {
            title: "Environment"
            description: "Values are read from the live session; nothing here is simulated."
            Layout.fillWidth: true

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 24
                rowSpacing: 8

                Text { text: "AETHER"; color: Theme.onSurfaceVariant; font.family: Theme.fontFamily; font.pixelSize: Theme.fs(10.5) }
                Text { Layout.fillWidth: true; text: Config.aetherVersion; color: Theme.onSurface; font.family: Theme.fontMono; font.pixelSize: Theme.fs(10.5) }

                Text { text: "Quickshell"; color: Theme.onSurfaceVariant; font.family: Theme.fontFamily; font.pixelSize: Theme.fs(10.5) }
                Text { Layout.fillWidth: true; text: page.quickshellVersion; color: Theme.onSurface; font.family: Theme.fontMono; font.pixelSize: Theme.fs(10.5) }

                Text { text: "Hyprland"; color: Theme.onSurfaceVariant; font.family: Theme.fontFamily; font.pixelSize: Theme.fs(10.5) }
                Text { Layout.fillWidth: true; text: page.hyprlandVersion; color: Theme.onSurface; font.family: Theme.fontMono; font.pixelSize: Theme.fs(10.5) }

                Text { text: "Qt"; color: Theme.onSurfaceVariant; font.family: Theme.fontFamily; font.pixelSize: Theme.fs(10.5) }
                Text { Layout.fillWidth: true; text: Qt.application.version; color: Theme.onSurface; font.family: Theme.fontMono; font.pixelSize: Theme.fs(10.5) }

                Text { text: "Session"; color: Theme.onSurfaceVariant; font.family: Theme.fontFamily; font.pixelSize: Theme.fs(10.5) }
                Text {
                    Layout.fillWidth: true
                    text: (Quickshell.env("XDG_SESSION_TYPE") || "unknown")
                        + " · " + (Quickshell.env("XDG_CURRENT_DESKTOP") || "unknown desktop")
                    color: Theme.onSurface
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fs(10.5)
                }

                Text { text: "Hostname"; color: Theme.onSurfaceVariant; font.family: Theme.fontFamily; font.pixelSize: Theme.fs(10.5) }
                Text { Layout.fillWidth: true; text: System.hostname; color: Theme.onSurface; font.family: Theme.fontMono; font.pixelSize: Theme.fs(10.5) }
            }
        }

        SettingsCard {
            title: "Paths"
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { label: "Installation", value: Config.installRoot },
                        { label: "Configuration", value: Config.configDir },
                        { label: "State", value: Config.stateDir },
                        { label: "Bundled themes", value: Config.themesDir },
                        { label: "User themes", value: Config.userThemesDir }
                    ]
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 12
                        Text {
                            Layout.preferredWidth: 110
                            text: modelData.label
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(10)
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.value
                            color: Theme.onSurface
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fs(9.5)
                            elide: Text.ElideMiddle
                        }
                    }
                }
            }
        }

        SettingsCard {
            title: "Diagnostics"
            description: "Paste this into a bug report. It contains no secrets or Wi-Fi credentials."
            Layout.fillWidth: true

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: page.copiedHint.length > 0 ? page.copiedHint
                        : "Includes versions, session type and AETHER paths."
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(9.5)
                }
                Button {
                    label: "Copy diagnostics"
                    icon: "copy"
                    primary: false
                    implicitHeight: 30
                    onClicked: {
                        Quickshell.clipboardText = page.diagnostics();
                        page.copiedHint = "Copied to the clipboard.";
                    }
                }
                Button {
                    label: "Open config folder"
                    icon: "folder"
                    primary: false
                    implicitHeight: 30
                    onClicked: Quickshell.execDetached(["xdg-open", Config.configDir])
                }
            }
        }

        SettingsCard {
            title: "Credits"
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "AETHER stands on the work of the Hyprland, Quickshell, Qt, PipeWire, NetworkManager, BlueZ and Arch Linux communities. Icons and wallpapers are original to this project unless noted in their licence files."
                color: Theme.onSurfaceVariant
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fs(10)
                wrapMode: Text.WordWrap
                lineHeight: 1.25
            }
        }
    }

    property StdioCollector quickshellOut: StdioCollector {
        waitForEnd: true
        onStreamFinished: {
            const line = quickshellOut.text.trim().split("\n")[0];
            if (line.length > 0) page.quickshellVersion = line;
        }
    }

    property Process quickshellProbe: Process {
        command: ["quickshell", "--version"]
        stdout: page.quickshellOut
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (page.quickshellVersion === "checking…") page.quickshellVersion = "unavailable"
        }
        onExited: (code, status) => {
            if (code !== 0 && page.quickshellVersion === "checking…")
                page.quickshellVersion = "unavailable";
        }
    }

    property StdioCollector hyprlandOut: StdioCollector {
        waitForEnd: true
        onStreamFinished: {
            const text = hyprlandOut.text.trim();
            if (text.length === 0) return;
            try {
                const doc = JSON.parse(text);
                page.hyprlandVersion = doc.version || doc.tag || "available";
            } catch (e) {
                page.hyprlandVersion = text.split("\n")[0];
            }
        }
    }

    property Process hyprlandProbe: Process {
        command: ["hyprctl", "version", "-j"]
        stdout: page.hyprlandOut
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (page.hyprlandVersion === "checking…") page.hyprlandVersion = "unavailable"
        }
        onExited: (code, status) => {
            if (code !== 0 && page.hyprlandVersion === "checking…")
                page.hyprlandVersion = "unavailable";
        }
    }

    Component.onCompleted: {
        quickshellProbe.running = true;
        hyprlandProbe.running = true;
    }
}
