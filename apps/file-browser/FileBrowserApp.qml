import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import "../../shell/Aether"

// A straightforward, real filesystem browser. It reads directories through
// FolderListModel and opens files with xdg-open using an argument array.
Item {
    id: root

    readonly property string home: Quickshell.env("HOME") || "/"
    property string currentPath: root.home
    property string searchText: ""
    property bool showHidden: false
    property bool gridMode: false
    property var history: [root.home]
    property int historyIndex: 0

    readonly property string folderUrl: root.currentPath.length > 0
        ? encodeURI("file://" + root.currentPath) : ""

    readonly property var places: [
        { label: "Home", icon: "home", path: root.home },
        { label: "Documents", icon: "file", path: root.home + "/Documents" },
        { label: "Downloads", icon: "download", path: root.home + "/Downloads" },
        { label: "Pictures", icon: "image", path: root.home + "/Pictures" },
        { label: "Music", icon: "music", path: root.home + "/Music" },
        { label: "Videos", icon: "monitor", path: root.home + "/Videos" },
        { label: "Root", icon: "disk", path: "/" }
    ]

    function navigate(path) {
        if (!path || path.length === 0) return;
        let clean = path;
        while (clean.length > 1 && clean.endsWith("/")) clean = clean.slice(0, -1);
        if (!clean.startsWith("/")) return;
        root.currentPath = clean;
        root.searchText = "";
        const next = root.history.slice(0, root.historyIndex + 1);
        next.push(clean);
        root.history = next;
        root.historyIndex = next.length - 1;
    }

    function goBack() {
        if (root.historyIndex <= 0) return;
        root.historyIndex -= 1;
        root.currentPath = root.history[root.historyIndex];
        root.searchText = "";
    }

    function goForward() {
        if (root.historyIndex >= root.history.length - 1) return;
        root.historyIndex += 1;
        root.currentPath = root.history[root.historyIndex];
        root.searchText = "";
    }

    function goUp() {
        if (root.currentPath === "/") return;
        const parts = root.currentPath.split("/").filter((p) => p.length > 0);
        parts.pop();
        root.navigate("/" + parts.join("/"));
    }

    function openEntry(path, isDir) {
        if (isDir) root.navigate(path);
        else Quickshell.execDetached(["xdg-open", path]);
    }

    function fileIcon(name, isDir) {
        if (isDir) return "folder";
        const ext = String(name || "").split(".").pop().toLowerCase();
        if (["png", "jpg", "jpeg", "webp", "gif", "svg", "bmp"].indexOf(ext) !== -1) return "image";
        if (["mp3", "flac", "ogg", "wav", "m4a", "opus"].indexOf(ext) !== -1) return "music";
        if (["mp4", "mkv", "webm", "mov", "avi"].indexOf(ext) !== -1) return "monitor";
        if (["zip", "tar", "gz", "xz", "zst", "7z", "rar"].indexOf(ext) !== -1) return "download";
        if (["sh", "bash", "zsh", "py", "rs", "js", "ts", "json", "toml", "yaml", "yml", "qml", "c", "h", "cpp"].indexOf(ext) !== -1) return "terminal";
        if (["pdf", "md", "txt", "conf", "ini", "log"].indexOf(ext) !== -1) return "file";
        return "file";
    }

    function formatSize(bytes) {
        const n = Number(bytes);
        if (!isFinite(n) || n < 0) return "";
        if (n < 1024) return n + " B";
        const units = ["KiB", "MiB", "GiB", "TiB"];
        let v = n / 1024;
        let i = 0;
        while (v >= 1024 && i < units.length - 1) { v /= 1024; i++; }
        return (v >= 100 ? Math.round(v) : v.toFixed(1)) + " " + units[i];
    }

    function formatDate(modified) {
        if (!modified) return "";
        if (modified instanceof Date) return Qt.formatDateTime(modified, "yyyy-MM-dd HH:mm");
        const parsed = new Date(modified);
        if (isNaN(parsed.getTime())) return "";
        return Qt.formatDateTime(parsed, "yyyy-MM-dd HH:mm");
    }

    FolderListModel {
        id: folderModel
        folder: root.folderUrl
        showDirsFirst: true
        showHidden: root.showHidden
        showOnlyReadable: false
        nameFilters: root.searchText.length > 0 ? ["*" + root.searchText + "*"] : ["*"]
        sortField: FolderListModel.Name
        sortReversed: false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ---------------- Toolbar ----------------
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 66
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 6

                IconButton {
                    icon: "arrow-left"; iconSize: 16; buttonSize: 32
                    enabled: root.historyIndex > 0
                    accessibleName: "Back"
                    onClicked: root.goBack()
                }
                IconButton {
                    icon: "arrow-right"; iconSize: 16; buttonSize: 32
                    enabled: root.historyIndex < root.history.length - 1
                    accessibleName: "Forward"
                    onClicked: root.goForward()
                }
                IconButton {
                    icon: "arrow-up"; iconSize: 16; buttonSize: 32
                    enabled: root.currentPath !== "/"
                    accessibleName: "Up one folder"
                    onClicked: root.goUp()
                }
                IconButton {
                    icon: "home"; iconSize: 16; buttonSize: 32
                    accessibleName: "Home"
                    onClicked: root.navigate(root.home)
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: Theme.radiusSm
                    color: Theme.surfaceContainer
                    border.width: 1
                    border.color: pathInput.activeFocus ? Theme.primary : Theme.hairline
                    TextInput {
                        id: pathInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.onSurface
                        selectionColor: Theme.primary
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fs(11)
                        text: root.currentPath
                        onAccepted: root.navigate(text.trim())
                    }
                }

                Rectangle {
                    width: 190
                    height: 36
                    radius: Theme.radiusSm
                    color: Theme.surfaceContainer
                    border.width: 1
                    border.color: searchInput.activeFocus ? Theme.primary : Theme.hairline
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6
                        Icon { name: "search"; size: 13; color: Theme.onSurfaceVariant }
                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.onSurface
                            selectionColor: Theme.primary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fs(11)
                            onTextChanged: root.searchText = text
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: searchInput.text.length === 0
                                text: "Filter this folder"
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(11)
                                opacity: 0.7
                            }
                        }
                    }
                }

                IconButton {
                    icon: "eye"; iconSize: 16; buttonSize: 32
                    active: root.showHidden
                    accessibleName: root.showHidden ? "Hide hidden files" : "Show hidden files"
                    onClicked: root.showHidden = !root.showHidden
                }
                IconButton {
                    icon: root.gridMode ? "list" : "grid"; iconSize: 16; buttonSize: 32
                    accessibleName: root.gridMode ? "List view" : "Grid view"
                    onClicked: root.gridMode = !root.gridMode
                }
                IconButton {
                    icon: "terminal"; iconSize: 16; buttonSize: 32
                    accessibleName: "Open terminal here"
                    onClicked: Quickshell.execDetached(["aether-terminal", "--working-directory", root.currentPath])
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hairline }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ---------------- Places ----------------
            Rectangle {
                Layout.preferredWidth: 208
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
                    anchors.margins: 12
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 6
                        text: "PLACES"
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(9)
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.9
                    }

                    Repeater {
                        model: root.places
                        delegate: Rectangle {
                            id: placeRow
                            required property var modelData
                            readonly property bool active: root.currentPath === placeRow.modelData.path
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            radius: Theme.radiusSm
                            color: placeRow.active ? Theme.selected
                                : (placeHover.hovered ? Theme.hover : "transparent")

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 9
                                anchors.rightMargin: 9
                                spacing: 9
                                Icon {
                                    name: placeRow.modelData.icon
                                    size: 15
                                    color: placeRow.active ? Theme.primary : Theme.onSurfaceVariant
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: placeRow.modelData.label
                                    color: placeRow.active ? Theme.onSurface : Theme.onSurfaceVariant
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(11)
                                    font.weight: placeRow.active ? Font.DemiBold : Font.Normal
                                }
                            }

                            HoverHandler { id: placeHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                acceptedButtons: Qt.LeftButton
                                onTapped: root.navigate(placeRow.modelData.path)
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        Layout.fillWidth: true
                        text: folderModel.count + " entries"
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(9)
                    }
                    Text {
                        Layout.fillWidth: true
                        text: folderModel.status === FolderListModel.Ready
                            ? "Ready" : "Cannot read this folder"
                        color: folderModel.status === FolderListModel.Ready
                            ? Theme.onSurfaceVariant : Theme.error
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(9)
                    }
                }
            }

            // ---------------- Contents ----------------
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Grid view
                Flickable {
                    anchors.fill: parent
                    visible: root.gridMode
                    clip: true
                    contentWidth: width
                    contentHeight: gridBody.implicitHeight + 32
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    GridLayout {
                        id: gridBody
                        x: 16
                        y: 16
                        width: parent.width - 32
                        columns: Math.max(2, Math.floor(width / 178))
                        columnSpacing: 12
                        rowSpacing: 12

                        Repeater {
                            model: folderModel
                            delegate: Rectangle {
                                id: gridTile
                                required property string fileName
                                required property string filePath
                                required property bool fileIsDir
                                required property url fileURL
                                Layout.fillWidth: true
                                Layout.preferredHeight: 168
                                radius: Theme.radiusSm
                                color: gridHover.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainer
                                border.width: 1
                                border.color: Theme.hairline

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: Theme.radiusSm
                                        color: Theme.surfaceContainerHighest
                                        clip: true

                                        Image {
                                            id: tileImage
                                            anchors.fill: parent
                                            source: gridTile.fileIsDir ? "" : gridTile.fileURL
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                            visible: !gridTile.fileIsDir && status === Image.Ready
                                        }
                                        Icon {
                                            anchors.centerIn: parent
                                            visible: gridTile.fileIsDir || tileImage.status !== Image.Ready
                                            name: root.fileIcon(gridTile.fileName, gridTile.fileIsDir)
                                            size: 36
                                            color: gridTile.fileIsDir ? Theme.primary : Theme.onSurfaceVariant
                                            opacityOverride: gridTile.fileIsDir ? 0.9 : 0.55
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: gridTile.fileName
                                        color: Theme.onSurface
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fs(10)
                                        font.weight: Font.Medium
                                        elide: Text.ElideMiddle
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }

                                HoverHandler { id: gridHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler {
                                    acceptedButtons: Qt.LeftButton
                                    onTapped: root.openEntry(gridTile.filePath, gridTile.fileIsDir)
                                }
                            }
                        }
                    }
                }

                // List view
                ListView {
                    anchors.fill: parent
                    visible: !root.gridMode
                    clip: true
                    model: folderModel
                    spacing: 1
                    topMargin: 4
                    leftMargin: 12
                    rightMargin: 12
                    bottomMargin: 12
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    header: Item {
                        width: ListView.view ? ListView.view.width : 0
                        height: 30
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 38
                            anchors.rightMargin: 8
                            spacing: 8
                            Text { Layout.fillWidth: true; text: "NAME"; color: Theme.onSurfaceVariant; font.family: Theme.fontFamily; font.pixelSize: Theme.fs(8.5); font.weight: Font.DemiBold; font.letterSpacing: 0.7 }
                            Text { Layout.preferredWidth: 90; text: "SIZE"; color: Theme.onSurfaceVariant; font.family: Theme.fontFamily; font.pixelSize: Theme.fs(8.5); font.weight: Font.DemiBold; font.letterSpacing: 0.7; horizontalAlignment: Text.AlignRight }
                            Text { Layout.preferredWidth: 132; text: "MODIFIED"; color: Theme.onSurfaceVariant; font.family: Theme.fontFamily; font.pixelSize: Theme.fs(8.5); font.weight: Font.DemiBold; font.letterSpacing: 0.7; horizontalAlignment: Text.AlignRight }
                        }
                    }

                    delegate: Rectangle {
                        id: listRow
                        required property string fileName
                        required property string filePath
                        required property bool fileIsDir
                        required property var fileSize
                        required property var fileModified
                        width: ListView.view ? ListView.view.width : 0
                        height: 38
                        radius: Theme.radiusSm
                        color: listHover.hovered ? Theme.hover : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8
                            Icon {
                                name: root.fileIcon(listRow.fileName, listRow.fileIsDir)
                                size: 17
                                color: listRow.fileIsDir ? Theme.primary : Theme.onSurfaceVariant
                            }
                            Text {
                                Layout.fillWidth: true
                                text: listRow.fileName
                                color: Theme.onSurface
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(11)
                                elide: Text.ElideMiddle
                            }
                            Text {
                                Layout.preferredWidth: 90
                                text: listRow.fileIsDir ? "" : root.formatSize(listRow.fileSize)
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fs(9)
                                horizontalAlignment: Text.AlignRight
                            }
                            Text {
                                Layout.preferredWidth: 132
                                text: root.formatDate(listRow.fileModified)
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fs(9)
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        HoverHandler { id: listHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: root.openEntry(listRow.filePath, listRow.fileIsDir)
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 80, 400)
                    spacing: 6
                    visible: folderModel.count === 0

                    Icon {
                        Layout.alignment: Qt.AlignHCenter
                        name: "folder"
                        size: 40
                        color: Theme.onSurfaceVariant
                        opacityOverride: 0.5
                    }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: folderModel.status === FolderListModel.Ready
                            ? (root.searchText.length > 0 ? "No matches in this folder" : "This folder is empty")
                            : "Cannot read this folder"
                        color: Theme.onSurface
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(13)
                        font.weight: Font.DemiBold
                    }
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: folderModel.status === FolderListModel.Ready
                            ? "Use the path bar to go somewhere else."
                            : "Check permissions or choose another location."
                        color: Theme.onSurfaceVariant
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fs(10)
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    onCurrentPathChanged: {
        if (!pathInput.activeFocus) pathInput.text = root.currentPath;
    }
}
