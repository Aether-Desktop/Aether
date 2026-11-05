import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../shell/Aether"

// AETHER Music is a first-party MPRIS client. It controls whichever player the
// user selects and never fabricates a library or queue the player does not expose.
Item {
    id: root

    property var selectedPlayer: null

    readonly property var players: System.players
    readonly property var player: {
        const list = root.players;
        if (root.selectedPlayer) {
            for (let i = 0; i < list.length; i++)
                if (list[i] === root.selectedPlayer) return root.selectedPlayer;
        }
        for (let i = 0; i < list.length; i++)
            if (list[i].isPlaying) return list[i];
        return list.length > 0 ? list[0] : null;
    }

    readonly property bool hasPlayer: root.player !== null
    readonly property string title: root.player ? (root.player.trackTitle || "Unknown track") : ""
    readonly property string artist: root.player ? (root.player.trackArtist || "") : ""
    readonly property string album: root.player ? (root.player.trackAlbum || "") : ""
    readonly property string artUrl: root.player ? (root.player.trackArtUrl || "") : ""
    readonly property real position: root.player ? root.player.position : 0
    readonly property real length: root.player ? root.player.length : 0
    readonly property bool playing: root.player ? root.player.isPlaying : false

    function formatTime(seconds) {
        if (!isFinite(seconds) || seconds <= 0) return "0:00";
        const total = Math.floor(seconds);
        const m = Math.floor(total / 60);
        const s = total % 60;
        return m + ":" + (s < 10 ? "0" + s : s);
    }

    function seek(seconds) {
        if (!root.player || !root.player.positionSupported) return;
        root.player.position = Math.max(0, Math.min(root.length, seconds));
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---------------- Sidebar ----------------
        Rectangle {
            Layout.preferredWidth: 288
            Layout.fillHeight: true
            color: Theme.surfaceContainer

            Rectangle {
                anchors.right: parent.right
                width: 1
                height: parent.height
                color: Theme.hairline
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: Theme.radiusSm
                        color: Theme.primaryContainer
                        Icon {
                            anchors.centerIn: parent
                            name: "music"
                            size: 17
                            color: Theme.primary
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Text {
                            text: "AETHER"
                            color: Theme.onSurface
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(14)
                            font.weight: Font.Bold
                            font.letterSpacing: 1.5
                        }
                        Text {
                            text: "Music"
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(9.5)
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    text: "PLAYERS"
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(9)
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.9
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Repeater {
                        model: root.players
                        delegate: Rectangle {
                            id: playerRow
                            required property var modelData
                            readonly property bool active: root.player === playerRow.modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            radius: Theme.radiusSm
                            color: playerRow.active ? Theme.selected
                                : (playerHover.hovered ? Theme.hover : "transparent")

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 9
                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 8
                                    color: Theme.surfaceContainerHighest
                                    Icon {
                                        anchors.centerIn: parent
                                        name: playerRow.modelData.isPlaying ? "pause" : "play"
                                        size: 13
                                        color: playerRow.active ? Theme.primary : Theme.onSurfaceVariant
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Text {
                                        Layout.fillWidth: true
                                        text: playerRow.modelData.identity || "Media player"
                                        color: Theme.onSurface
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fs(11)
                                        font.weight: playerRow.active ? Font.DemiBold : Font.Medium
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: playerRow.modelData.trackTitle || "No track"
                                        color: Theme.onSurfaceVariant
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fs(9)
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            HoverHandler { id: playerHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                acceptedButtons: Qt.LeftButton
                                onTapped: root.selectedPlayer = playerRow.modelData
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: root.players.length === 0
                        text: "No MPRIS players are running. Start a player such as Amberol, Lollypop or a browser tab."
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(10)
                        wrapMode: Text.WordWrap
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.hairline
                }

                Text {
                    Layout.fillWidth: true
                    text: "Playback is controlled through MPRIS. AETHER does not index or copy your library."
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(9)
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Icon { name: System.muted ? "volume-mute" : "volume"; size: 14; color: Theme.onSurfaceVariant }
                    Slider {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 24
                        value: root.player ? root.player.volume : 0
                        from: 0
                        to: 1
                        stepSize: 0.01
                        enabled: root.hasPlayer && root.player.volumeSupported
                        onMoved: (v) => { if (root.player) root.player.volume = v; }
                    }
                }
            }
        }

        // ---------------- Main ----------------
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 32
                spacing: 16
                visible: root.hasPlayer

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 24

                    Rectangle {
                        Layout.preferredWidth: 260
                        Layout.preferredHeight: 260
                        radius: Theme.radiusLg
                        color: Theme.surfaceContainerHigh
                        clip: true

                        Image {
                            id: art
                            anchors.fill: parent
                            source: root.artUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: status === Image.Ready
                        }
                        Icon {
                            anchors.centerIn: parent
                            visible: art.status !== Image.Ready
                            name: "music"
                            size: 68
                            color: Theme.onSurfaceVariant
                            opacityOverride: 0.5
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: "transparent"
                            border.width: 1
                            border.color: Theme.hairline
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: root.title
                            color: Theme.onSurface
                            font.family: Theme.fontDisplay
                            font.pixelSize: Theme.fs(28)
                            font.weight: Font.Bold
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.artist.length > 0 ? root.artist : "Unknown artist"
                            color: Theme.primary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(15)
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.album
                            visible: root.album.length > 0
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(12)
                            elide: Text.ElideRight
                        }

                        Item { Layout.preferredHeight: 8 }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                text: root.formatTime(root.position)
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fs(10)
                            }
                            Slider {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 26
                                value: root.position
                                from: 0
                                to: Math.max(1, root.length)
                                enabled: root.player && root.player.positionSupported
                                onMoved: (v) => root.seek(v)
                            }
                            Text {
                                text: root.formatTime(root.length)
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fs(10)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            spacing: 10
                            Item { Layout.fillWidth: true }
                            IconButton {
                                icon: "shuffle"
                                iconSize: 15
                                buttonSize: 34
                                visible: root.player && root.player.shuffleSupported
                                active: root.player ? root.player.shuffle : false
                                accessibleName: "Shuffle"
                                onClicked: {
                                    if (root.player) root.player.shuffle = !root.player.shuffle;
                                }
                            }
                            IconButton {
                                icon: "prev"
                                iconSize: 20
                                buttonSize: 42
                                enabled: root.player && root.player.canGoPrevious
                                accessibleName: "Previous track"
                                onClicked: { if (root.player) root.player.previous(); }
                            }
                            Rectangle {
                                width: 58
                                height: 58
                                radius: 29
                                color: playHover.hovered ? Qt.lighter(Theme.primary, 1.08) : Theme.primary
                                Icon {
                                    anchors.centerIn: parent
                                    name: root.playing ? "pause" : "play"
                                    size: 24
                                    color: Theme.onPrimary
                                }
                                HoverHandler { id: playHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler {
                                    acceptedButtons: Qt.LeftButton
                                    enabled: root.player && root.player.canTogglePlaying
                                    onTapped: { if (root.player) root.player.togglePlaying(); }
                                }
                            }
                            IconButton {
                                icon: "next"
                                iconSize: 20
                                buttonSize: 42
                                enabled: root.player && root.player.canGoNext
                                accessibleName: "Next track"
                                onClicked: { if (root.player) root.player.next(); }
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.hairline
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Icon { name: "activity"; size: 15; color: Theme.onSurfaceVariant }
                    Text {
                        Layout.fillWidth: true
                        text: root.player
                            ? (root.player.identity || "Player")
                                + (root.player.desktopEntry ? " · " + root.player.desktopEntry : "")
                            : ""
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(9.5)
                        elide: Text.ElideRight
                    }
                    Text {
                        text: root.player && root.player.canSeek ? "Seekable" : "Seeking unavailable"
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(9)
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width - 80, 460)
                spacing: 10
                visible: !root.hasPlayer

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 88
                    height: 88
                    radius: 44
                    color: Theme.surfaceContainerHigh
                    Icon {
                        anchors.centerIn: parent
                        name: "music"
                        size: 38
                        color: Theme.onSurfaceVariant
                    }
                }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "Nothing playing"
                    color: Theme.onSurface
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.fs(22)
                    font.weight: Font.DemiBold
                }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "AETHER Music appears when an MPRIS-compatible player is running. Start your music application and it will show up here."
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(11)
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
