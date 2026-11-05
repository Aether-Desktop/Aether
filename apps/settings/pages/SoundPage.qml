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
            title: "Output"
            description: "Levels and device selection are applied through PipeWire."
            Layout.fillWidth: true

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Icon {
                    name: System.muted || System.volume <= 0.001 ? "volume-mute" : "volume"
                    size: 16
                    color: Theme.primary
                }
                Text {
                    Layout.fillWidth: true
                    text: System.audioAvailable ? System.sinkName : "No output device"
                    color: Theme.onSurface
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(11.5)
                    elide: Text.ElideRight
                }
            }
            SettingsSliderRow {
                Layout.fillWidth: true
                title: "Volume"
                value: System.volume
                from: 0
                to: 1
                stepSize: 0.01
                available: System.audioAvailable
                valueText: System.audioAvailable ? System.volumePercent() + "%" : "unavailable"
                onMoved: (v) => System.setVolume(v)
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Mute output"
                checked: System.muted
                onToggled: (value) => { if (System.sinkAudio) System.sinkAudio.muted = value; }
            }
        }

        SettingsCard {
            title: "Output devices"
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: System.sinks
                    delegate: Rectangle {
                        id: sinkRow
                        required property var modelData
                        readonly property bool isDefault: System.sink === sinkRow.modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        radius: Theme.radiusSm
                        color: sinkRow.isDefault ? Theme.selected : (sinkHover.hovered ? Theme.hover : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 9
                            Icon {
                                name: "volume"
                                size: 15
                                color: sinkRow.isDefault ? Theme.primary : Theme.onSurfaceVariant
                            }
                            Text {
                                Layout.fillWidth: true
                                text: sinkRow.modelData.description || sinkRow.modelData.name
                                color: Theme.onSurface
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(11.5)
                                elide: Text.ElideRight
                            }
                            Text {
                                visible: sinkRow.isDefault
                                text: "Default"
                                color: Theme.primary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(9)
                                font.weight: Font.DemiBold
                            }
                        }

                        HoverHandler { id: sinkHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: System.setDefaultSink(sinkRow.modelData)
                        }
                    }
                }

                Text {
                    visible: System.sinks.length === 0
                    text: "No PipeWire sinks detected."
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(10)
                }
            }
        }

        SettingsCard {
            title: "Input"
            Layout.fillWidth: true

            SettingsSliderRow {
                Layout.fillWidth: true
                title: "Microphone volume"
                value: System.micVolume
                from: 0
                to: 1
                stepSize: 0.01
                available: System.sourceAudio !== null
                valueText: System.sourceAudio !== null ? Math.round(System.micVolume * 100) + "%" : "unavailable"
                onMoved: (v) => System.setMicVolume(v)
            }
            SettingsToggleRow {
                Layout.fillWidth: true
                title: "Mute microphone"
                checked: System.micMuted
                onToggled: (value) => { if (System.sourceAudio) System.sourceAudio.muted = value; }
            }
        }

        SettingsCard {
            title: "Input devices"
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: System.sources
                    delegate: Rectangle {
                        id: sourceRow
                        required property var modelData
                        readonly property bool isDefault: System.source === sourceRow.modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        radius: Theme.radiusSm
                        color: sourceRow.isDefault ? Theme.selected : (sourceHover.hovered ? Theme.hover : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 9
                            Icon {
                                name: "music"
                                size: 15
                                color: sourceRow.isDefault ? Theme.primary : Theme.onSurfaceVariant
                            }
                            Text {
                                Layout.fillWidth: true
                                text: sourceRow.modelData.description || sourceRow.modelData.name
                                color: Theme.onSurface
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(11.5)
                                elide: Text.ElideRight
                            }
                            Text {
                                visible: sourceRow.isDefault
                                text: "Default"
                                color: Theme.primary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(9)
                                font.weight: Font.DemiBold
                            }
                        }

                        HoverHandler { id: sourceHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: System.setDefaultSource(sourceRow.modelData)
                        }
                    }
                }

                Text {
                    visible: System.sources.length === 0
                    text: "No PipeWire sources detected."
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(10)
                }
            }
        }
    }
}
