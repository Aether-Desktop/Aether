import QtQuick
import Quickshell
import "../../shell/Aether"

ShellRoot {
    FloatingWindow {
        id: win

        title: "AETHER Settings"
        color: Theme.background
        implicitWidth: 1120
        implicitHeight: 760
        minimumSize.width: 820
        minimumSize.height: 560
        visible: true

        SettingsApp {
            anchors.fill: parent
        }
    }
}
