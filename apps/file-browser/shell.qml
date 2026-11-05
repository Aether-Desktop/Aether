import QtQuick
import Quickshell
import "../../shell/Aether"

ShellRoot {
    FloatingWindow {
        title: "AETHER Files"
        color: Theme.background
        implicitWidth: 1160
        implicitHeight: 760
        minimumSize.width: 840
        minimumSize.height: 560
        visible: true

        FileBrowserApp {
            anchors.fill: parent
        }
    }
}
