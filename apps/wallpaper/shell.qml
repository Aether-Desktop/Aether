import QtQuick
import Quickshell
import "../../shell/Aether"

ShellRoot {
    FloatingWindow {
        title: "AETHER Wallpaper"
        color: Theme.background
        implicitWidth: 1120
        implicitHeight: 760
        minimumSize.width: 820
        minimumSize.height: 560
        visible: true

        WallpaperApp {
            anchors.fill: parent
        }
    }
}
