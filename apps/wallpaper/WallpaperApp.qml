import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../../shell/Aether"

Item {
    id: root

    property string status: "checking wallpaper backend…"
    property string helperError: ""
    property bool applying: false

    readonly property string currentPath: Config.appearance.wallpaper || ""
    readonly property string userWallpaperDir: Config.configDir + "/wallpapers"

    function apply(path) {
        if (!path || path.length === 0) return;
        Config.set("appearance.wallpaper", path);
        root.applying = true;
        root.helperError = "";
        applyProcess.command = ["aether-wallpaper", "set", path];
        applyProcess.running = true;
        root.status = "Wallpaper stored. Asking the compositor backend…";
    }

    function refreshStatus() {
        if (!statusProcess.running) statusProcess.running = true;
    }

    property StdioCollector statusOut: StdioCollector {
        waitForEnd: true
        onStreamFinished: {
            const text = statusOut.text.trim();
            if (text.length > 0) root.status = text;
        }
    }

    property StdioCollector applyOut: StdioCollector {
        waitForEnd: true
        onStreamFinished: {
            const text = applyOut.text.trim();
            if (text.length > 0) root.status = text;
        }
    }

    property StdioCollector applyErr: StdioCollector {
        waitForEnd: true
        onStreamFinished: if (text.trim().length > 0) root.helperError = text.trim()
    }

    property Process statusProcess: Process {
        command: ["aether-wallpaper", "status"]
        stdout: root.statusOut
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (text.trim().length > 0) root.status = "Backend check failed"
        }
        onExited: (code, status) => {
            if (code !== 0 && root.status === "checking wallpaper backend…")
                root.status = "aether-wallpaper is not available on PATH.";
        }
    }

    property Process applyProcess: Process {
        stdout: root.applyOut
        stderr: root.applyErr
        onExited: (code, status) => {
            root.applying = false;
            if (code !== 0) {
                if (root.helperError.length === 0)
                    root.helperError = "The compositor backend rejected the change. The path is saved in AETHER config.";
            }
        }
    }

    FolderListModel {
        id: bundledModel
        folder: encodeURI("file://" + Config.assetsDir + "/wallpapers")
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.svg"]
        showDirs: false
        sortField: FolderListModel.Name
    }

    FolderListModel {
        id: userModel
        folder: encodeURI("file://" + root.userWallpaperDir)
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.svg"]
        showDirs: false
        sortField: FolderListModel.Name
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

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
                        text: "Wallpaper"
                        color: Theme.onSurface
                        font.family: Theme.fontDisplay
                        font.pixelSize: Theme.fs(22)
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: "Bundled artwork and your own images. AETHER stores the choice; a compositor backend paints it."
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
                    onClicked: root.refreshStatus()
                }
                Button {
                    label: "Open folders"
                    icon: "folder"
                    primary: false
                    implicitHeight: 32
                    onClicked: Quickshell.execDetached(["xdg-open", root.userWallpaperDir])
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hairline }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: body.implicitHeight + 40
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: body
                x: 26
                y: 20
                width: parent.width - 52
                spacing: 18

                Surface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 230
                    radius: Theme.radiusMd
                    fill: Theme.surfaceContainer
                    padding: 16
                    shadow: false

                    RowLayout {
                        anchors.fill: parent
                        spacing: 18

                        Rectangle {
                            Layout.preferredWidth: 340
                            Layout.fillHeight: true
                            radius: Theme.radiusSm
                            color: Theme.surfaceContainerHighest
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: Theme.wallpaperUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
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
                            Layout.fillHeight: true
                            spacing: 8

                            Text {
                                text: "Current wallpaper"
                                color: Theme.onSurface
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(13)
                                font.weight: Font.DemiBold
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.currentPath.length > 0 ? root.currentPath : "No wallpaper configured"
                                color: Theme.onSurfaceVariant
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fs(9.5)
                                wrapMode: Text.WrapAnywhere
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.status
                                color: root.status.indexOf("not") !== -1 || root.status.indexOf("failed") !== -1
                                    ? Theme.warning : Theme.onSurfaceVariant
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(9.5)
                                wrapMode: Text.WordWrap
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: root.helperError.length > 0
                                text: root.helperError
                                color: Theme.error
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fs(9.5)
                                wrapMode: Text.WordWrap
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 36
                                radius: Theme.radiusSm
                                color: Theme.surfaceContainerHighest
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
                                    onAccepted: root.apply(text.trim())
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: pathInput.text.length === 0
                                        text: "assets/wallpapers/aether-default.svg"
                                        color: Theme.onSurfaceVariant
                                        font.family: Theme.fontMono
                                        font.pixelSize: Theme.fs(11)
                                        opacity: 0.7
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text {
                                    Layout.fillWidth: true
                                    text: "Absolute paths are stored as-is; relative paths resolve inside the AETHER installation."
                                    color: Theme.onSurfaceVariant
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(9)
                                    wrapMode: Text.WordWrap
                                }
                                Button {
                                    label: "Apply path"
                                    icon: "check"
                                    primary: false
                                    implicitHeight: 30
                                    onClicked: root.apply(pathInput.text.trim())
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "BUNDLED WALLPAPERS"
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(9)
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.9
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: 12
                    rowSpacing: 12

                    Repeater {
                        model: bundledModel
                        delegate: Rectangle {
                            id: bundledTile
                            Layout.fillWidth: true
                            Layout.preferredHeight: 150
                            radius: Theme.radiusSm
                            color: Theme.surfaceContainer
                            clip: true
                            border.width: 1
                            border.color: root.currentPath.indexOf(fileName) !== -1 ? Theme.primary : Theme.hairline

                            Image {
                                anchors.fill: parent
                                source: fileURL
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                            }
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 34
                                color: Qt.rgba(0, 0, 0, 0.45)
                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: Text.AlignVCenter
                                    text: fileName
                                    color: "#FFFFFF"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(9.5)
                                    elide: Text.ElideMiddle
                                }
                            }

                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                acceptedButtons: Qt.LeftButton
                                onTapped: root.apply("assets/wallpapers/" + fileName)
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    text: "YOUR WALLPAPERS · " + root.userWallpaperDir
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(9)
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.9
                    elide: Text.ElideMiddle
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: 12
                    rowSpacing: 12

                    Repeater {
                        model: userModel
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 150
                            radius: Theme.radiusSm
                            color: Theme.surfaceContainer
                            clip: true
                            border.width: 1
                            border.color: root.currentPath === filePath ? Theme.primary : Theme.hairline

                            Image {
                                anchors.fill: parent
                                source: fileURL
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                            }
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 34
                                color: Qt.rgba(0, 0, 0, 0.45)
                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: Text.AlignVCenter
                                    text: fileName
                                    color: "#FFFFFF"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fs(9.5)
                                    elide: Text.ElideMiddle
                                }
                            }

                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                acceptedButtons: Qt.LeftButton
                                onTapped: root.apply(filePath)
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: userModel.count === 0
                    text: "No personal wallpapers yet. Copy JPG, PNG, WebP or SVG files into "
                        + root.userWallpaperDir + " and press Refresh."
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(10)
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    text: "Rendering note: SVG wallpapers are displayed by AETHER and must be rasterised by your wallpaper backend if it does not support SVG. AETHER does not silently convert files."
                    color: Theme.onSurfaceVariant
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fs(9)
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    Component.onCompleted: root.refreshStatus()

    onCurrentPathChanged: {
        if (!pathInput.activeFocus) pathInput.text = root.currentPath;
    }
}
