import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../shell/Aether"
import "../components"

Item {
    id: page

    implicitHeight: col.implicitHeight

    property string accentStatus: ""
    readonly property var accentPresets: [
        "#A99BFF", "#6FE7DD", "#FFB4C8", "#FFD28A", "#8BE3A2", "#7FB4FF", "#FF9E7A"
    ]

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 14

        SettingsCard {
            title: "Theme"
            description: "Themes are plain JSON files. Drop your own into ~/.config/aether/themes to override a bundled theme."
            Layout.fillWidth: true

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                rowSpacing: 10
                columnSpacing: 10

                Repeater {
                    model: Theme.availableThemes
                    delegate: Rectangle {
                        id: themeCard
                        required property var modelData
                        readonly property bool active: Theme.themeId === themeCard.modelData.id
                        readonly property var preview: themeCard.modelData.colors || ({})
                        Layout.fillWidth: true
                        Layout.preferredHeight: 84
                        radius: Theme.radiusSm
                        color: themeCard.active ? Theme.selected : Theme.surfaceContainerHigh
                        border.width: 1
                        border.color: themeCard.active ? Theme.primary : Theme.hairline

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 5
                                Rectangle {
                                    width: 14; height: 14; radius: 7
                                    color: themeCard.preview.primary || Theme.primary
                                }
                                Rectangle {
                                    width: 14; height: 14; radius: 7
                                    color: themeCard.preview.secondary || Theme.secondary
                                }
                                Rectangle {
                                    width: 14; height: 14; radius: 7
                                    color: themeCard.preview.surface || Theme.surface
                                    border.width: 1
                                    border.color: Theme.hairline
                                }
                                Item { Layout.fillWidth: true }
                                Icon {
                                    visible: themeCard.active
                                    name: "check"
                                    size: 13
                                    color: Theme.primary
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: themeCard.modelData.name
                                color: Theme.onSurface
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(11.5)
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                text: (themeCard.modelData.variant || "dark") + " · " + themeCard.modelData.id
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(9)
                                elide: Text.ElideRight
                            }
                        }

                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: Config.setTheme(themeCard.modelData.id)
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: Theme.userThemeActive
                        ? "Using a user theme override from ~/.config/aether/themes."
                        : "Using the bundled theme."
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(9.5)
                }
                Button {
                    label: "Open theme folder"
                    icon: "folder"
                    primary: false
                    implicitHeight: 30
                    onClicked: Quickshell.execDetached(["xdg-open", Config.userThemesDir])
                }
                Button {
                    label: "Reset theme"
                    icon: "activity"
                    primary: false
                    implicitHeight: 30
                    onClicked: {
                        Config.setTheme("aether-dark");
                        Config.setAccent(null);
                    }
                }
            }
        }

        SettingsCard {
            title: "Accent"
            description: "An explicit accent wins over the wallpaper-derived colour."
            Layout.fillWidth: true

            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Wallpaper accent"
                description: "Extract a colour from the current wallpaper with ColorQuantizer."
                checked: Config.appearance.wallpaperAccent === true
                onToggled: (value) => Config.set("appearance.wallpaperAccent", value)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: Config.appearance.accentOverride || Theme.accent
                    border.width: 2
                    border.color: Theme.onSurface
                    visible: !!Config.appearance.accentOverride
                }

                Repeater {
                    model: page.accentPresets
                    delegate: Rectangle {
                        required property string modelData
                        width: 26; height: 26; radius: 13
                        color: modelData
                        border.width: Config.appearance.accentOverride === modelData ? 2 : 0
                        border.color: Theme.onSurface
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: {
                                Config.setAccent(modelData);
                                page.accentStatus = "Accent set to " + modelData;
                            }
                        }
                    }
                }

                Chip {
                    label: "Automatic"
                    icon: "sparkles"
                    active: Config.appearance.accentOverride === null
                    onClicked: {
                        Config.setAccent(null);
                        page.accentStatus = "Using the wallpaper or theme accent";
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 190
                    height: 32
                    radius: Theme.radiusSm
                    color: Theme.surfaceContainerHighest
                    border.width: 1
                    border.color: Theme.hairline
                    TextInput {
                        id: hexInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.onSurface
                        selectionColor: Theme.primary
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fs(11)
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: hexInput.text.length === 0
                            text: "#RRGGBB"
                            color: Theme.onSurfaceVariant
                            font: hexInput.font
                            opacity: 0.7
                        }
                        onAccepted: page.applyHex(text)
                    }
                }
                Button {
                    label: "Apply"
                    primary: false
                    implicitHeight: 32
                    onClicked: page.applyHex(hexInput.text)
                }
            }

            Text {
                Layout.fillWidth: true
                visible: page.accentStatus.length > 0
                text: page.accentStatus
                color: Theme.onSurfaceVariant
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fs(9.5)
            }
        }

        SettingsCard {
            title: "Surface and motion"
            Layout.fillWidth: true

            SettingsSliderRow {
                Layout.fillWidth: true
                title: "Surface opacity"
                description: "Higher values are more opaque; Hyprland blur shows through lower values."
                value: Config.appearance.transparency || 0.86
                from: 0.4
                to: 1.0
                stepSize: 0.01
                valueText: Math.round((Config.appearance.transparency || 0.86) * 100) + "%"
                onMoved: (v) => Config.set("appearance.transparency", v)
            }
            SettingsSliderRow {
                Layout.fillWidth: true
                title: "Corner radius"
                value: Config.appearance.radiusScale || 1.0
                from: 0.5
                to: 1.6
                stepSize: 0.05
                valueText: Number(Config.appearance.radiusScale || 1).toFixed(2) + "×"
                onMoved: (v) => Config.set("appearance.radiusScale", v)
            }
            SettingsSliderRow {
                Layout.fillWidth: true
                title: "Font scale"
                value: Config.appearance.fontScale || 1.0
                from: 0.8
                to: 1.4
                stepSize: 0.05
                valueText: Number(Config.appearance.fontScale || 1).toFixed(2) + "×"
                onMoved: (v) => Config.set("appearance.fontScale", v)
            }
            SettingsTextField {
                Layout.fillWidth: true
                title: "Interface font family"
                value: Config.appearance.fontFamily || "Inter"
                placeholder: "Inter"
                onEdited: (value) => Config.set("appearance.fontFamily", value.trim())
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Compositor blur"
                description: "Stored intention for the generated Hyprland config; window blur is applied by Hyprland."
                checked: Config.appearance.blur === true
                onToggled: (value) => Config.set("appearance.blur", value)
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Reduced motion"
                description: "Disables AETHER animations across the shell and applications."
                checked: Config.animations.reducedMotion === true
                onToggled: (value) => Config.set("animations.reducedMotion", value)
            }
        }

        SettingsCard {
            title: "Wallpaper"
            description: "Use an absolute path or a path relative to the AETHER installation."
            Layout.fillWidth: true

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 260
                    Layout.preferredHeight: 120
                    radius: Theme.radiusSm
                    color: Theme.surfaceContainerHighest
                    clip: true
                    Image {
                        anchors.fill: parent
                        source: Theme.wallpaperUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text {
                        Layout.fillWidth: true
                        text: Config.appearance.wallpaper || "No wallpaper configured"
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fs(9.5)
                        elide: Text.ElideMiddle
                    }
                    SettingsTextField {
                        Layout.fillWidth: true
                        title: "Wallpaper path"
                        value: Config.appearance.wallpaper || ""
                        placeholder: "assets/wallpapers/aether-default.svg"
                        onEdited: (value) => Config.set("appearance.wallpaper", value.trim())
                    }
                }
            }
        }
    }

    function applyHex(text) {
        const value = String(text || "").trim();
        if (!/^#[0-9a-fA-F]{6}$/.test(value)) {
            page.accentStatus = "Enter a colour in #RRGGBB form";
            return;
        }
        Config.setAccent(value);
        hexInput.text = value;
        page.accentStatus = "Accent set to " + value;
    }
}
