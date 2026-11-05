import QtQuick
import Quickshell
import "../../shell/Aether"

ShellRoot {
    FloatingWindow {
        title: "AETHER Music"
        color: Theme.background
        implicitWidth: 1040
        implicitHeight: 680
        minimumSize.width: 760
        minimumSize.height: 540
        visible: true

        MusicApp {
            anchors.fill: parent
        }
    }
}
