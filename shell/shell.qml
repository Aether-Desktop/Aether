import QtQuick
import Quickshell
import "Aether"

// AETHER shell entry point.
// One bar, one overlay and one popup layer per monitor.
// Notify (singleton) owns the single notification daemon for the session.
ShellRoot {
    id: root

    Shortcuts {}

    Variants {
        model: Quickshell.screens

        delegate: Scope {
            id: screenScope
            property var modelData

            BarWindow { screenInfo: screenScope.modelData }
            OverlayWindow { screenInfo: screenScope.modelData }
            NotificationLayer { screenInfo: screenScope.modelData }
            OsdWindow { screenInfo: screenScope.modelData }
        }
    }
}
