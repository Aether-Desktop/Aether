import QtQuick
import Quickshell
import "../../shell/Aether"

ShellRoot {
    FloatingWindow {
        title: "AETHER Power"
        color: Theme.background
        implicitWidth: 440
        implicitHeight: 560
        minimumSize.width: 400
        minimumSize.height: 520
        visible: true

        PowerMenuApp {
            anchors.fill: parent
        }
    }
}
