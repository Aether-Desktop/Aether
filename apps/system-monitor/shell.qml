import QtQuick
import "../../shell/Aether"

ShellRoot {
    FloatingWindow {
        title: "AETHER System Monitor"
        color: Theme.background
        implicitWidth: 1180
        implicitHeight: 780
        minimumSize.width: 840
        minimumSize.height: 580
        visible: true

        SystemMonitorApp {
            anchors.fill: parent
        }
    }
}
