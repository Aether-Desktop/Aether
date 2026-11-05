import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Aether"

// Application launcher with fuzzy search, favourites and recent history.
// Runs desktop entries through their parsed Exec command (never a shell).
Item {
    id: root

    implicitWidth: 660
    implicitHeight: 560
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: Math.max(48, (parent.height - root.height) * 0.22)
    width: Math.min(root.implicitWidth, parent.width - 48)
    height: Math.min(root.implicitHeight, parent.height - 120)

    property string query: ""
    property int selected: 0
    property var allApps: {
        const apps = DesktopEntries.applications.values;
        const out = [];
        for (let i = 0; i < apps.length; i++) {
            const a = apps[i];
            if (!a || a.noDisplay || !a.name) continue;
            out.push(a);
        }
        out.sort((a, b) => a.name.localeCompare(b.name));
        return out;
    }
    readonly property var favorites: Config.launcher.favorites || []
    readonly property var recents: Config.launcher.recent || []

    readonly property var results: {
        const max = Math.max(1, Config.launcher.maxResults || 8);
        const q = root.query.trim();
        if (q.length === 0) {
            const out = [];
            const seen = ({});
            function add(a) {
                if (!a || seen[a.id]) return;
                seen[a.id] = true;
                out.push(a);
            }
            for (let i = 0; i < root.allApps.length; i++)
                if (root.favorites.indexOf(root.allApps[i].id) !== -1) add(root.allApps[i]);
            for (let i = 0; i < root.recents.length; i++) {
                for (let j = 0; j < root.allApps.length; j++)
                    if (root.allApps[j].id === root.recents[i]) add(root.allApps[j]);
            }
            for (let i = 0; i < root.allApps.length && out.length < 14; i++) add(root.allApps[i]);
            return out.slice(0, 14);
        }
        const scored = [];
        for (let i = 0; i < root.allApps.length; i++) {
            const a = root.allApps[i];
            const hay = a.name + " " + (a.genericName || "") + " " + (a.comment || "") + " " + (a.keywords || []).join(" ");
            const score = Util.fuzzyScore(hay, q);
            if (score >= 0) scored.push({ app: a, score: score, nameScore: Util.fuzzyScore(a.name, q) });
        }
        scored.sort((a, b) => (b.nameScore - a.nameScore) || (b.score - a.score));
        return scored.slice(0, max).map((x) => x.app);
    }

    function open() {
        search.forceActiveFocus();
    }

    function launch(app) {
        if (!app) return;
        Config.addRecent(app.id);
        UiState.close();
        app.execute();
    }

    onQueryChanged: root.selected = 0

    function move(delta) {
        if (root.results.length === 0) return;
        root.selected = Math.max(0, Math.min(root.results.length - 1, root.selected + delta));
    }

    Surface {
        anchors.fill: parent
        fill: Theme.glassHigh
        padding: 16
        radius: Theme.radiusLg

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Icon { name: "search"; size: 18; color: Theme.primary }

                TextInput {
                    id: search
                    Layout.fillWidth: true
                    focus: true
                    selectByMouse: true
                    color: Theme.onSurface
                    selectionColor: Theme.primary
                    selectedTextColor: Theme.onPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(17)
                    font.weight: Font.Medium
                    clip: true
                    onTextChanged: root.query = text
                    Keys.onDownPressed: root.move(1)
                    Keys.onUpPressed: root.move(-1)
                    Keys.onReturnPressed: root.launch(root.results[root.selected])
                    Keys.onEnterPressed: root.launch(root.results[root.selected])

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: search.text.length === 0
                        text: "Search applications…"
                        color: Theme.onSurfaceVariant
                        font: search.font
                        opacity: 0.75
                    }
                }

                IconButton {
                    visible: search.text.length > 0
                    icon: "close"; iconSize: 14; buttonSize: 28
                    accessibleName: "Clear search"
                    onClicked: { search.text = ""; search.forceActiveFocus(); }
                }

                Rectangle {
                    width: 1
                    height: 20
                    color: Theme.hairline
                }

                IconButton {
                    icon: "power"; iconSize: 16; buttonSize: 30
                    accessibleName: "Power menu"
                    onClicked: UiState.open("power")
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hairline }

            Text {
                Layout.fillWidth: true
                visible: root.query.trim().length === 0
                text: "Favourites and recent applications"
                color: Theme.onSurfaceVariant
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fs(10)
                font.weight: Font.DemiBold
                font.letterSpacing: 0.6
            }

            Flickable {
                id: scroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: listColumn.height
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: listColumn
                    width: scroll.width
                    spacing: 2

                    Repeater {
                        model: root.results
                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool selected: root.selected === index
                            readonly property bool favorite: root.favorites.indexOf(modelData.id) !== -1
                            width: listColumn.width
                            height: 50
                            radius: Theme.radiusSm
                            color: row.selected ? Theme.selected : (rowHover.hovered ? Theme.hover : "transparent")
                            Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 8
                                spacing: 12

                                AppIcon {
                                    Layout.preferredWidth: 30
                                    Layout.preferredHeight: 30
                                    iconName: row.modelData.icon || ""
                                    label: row.modelData.name
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Text {
                                        Layout.fillWidth: true
                                        text: row.modelData.name
                                        color: Theme.onSurface
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fs(13)
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: row.modelData.genericName || row.modelData.comment || row.modelData.id
                                        color: Theme.onSurfaceVariant
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fs(10)
                                        elide: Text.ElideRight
                                    }
                                }

                                IconButton {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    icon: row.favorite ? "sparkles" : "plus"
                                    iconSize: 13
                                    buttonSize: 28
                                    tint: row.favorite ? Theme.primary : Theme.onSurfaceVariant
                                    accessibleName: row.favorite ? "Remove favourite" : "Add favourite"
                                    onClicked: Config.toggleFavorite(row.modelData.id)
                                }

                                Icon {
                                    visible: row.selected
                                    name: "arrow-right"
                                    size: 14
                                    color: Theme.primary
                                }
                            }

                            HoverHandler {
                                id: rowHover
                                cursorShape: Qt.PointingHandCursor
                                onHoveredChanged: if (hovered) root.selected = row.index
                            }
                            TapHandler {
                                acceptedButtons: Qt.LeftButton
                                onTapped: root.launch(row.modelData)
                            }
                        }
                    }

                    Column {
                        visible: root.results.length === 0
                        width: parent.width
                        spacing: 6
                        Item { width: 1; height: 32 }
                        Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: "search"; size: 26; color: Theme.onSurfaceVariant
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No application matches “" + root.query + "”"
                            color: Theme.onSurfaceVariant
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(12)
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hairline }

            RowLayout {
                Layout.fillWidth: true
                spacing: 14
                Text {
                    text: root.results.length + (root.results.length === 1 ? " result" : " results")
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(9.5)
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "↑↓ navigate · Enter open · Esc close"
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(9.5)
                }
            }
        }
    }

    Component.onCompleted: Qt.callLater(root.open)
}
