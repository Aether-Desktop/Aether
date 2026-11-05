import QtQuick
import Quickshell
import Quickshell.Hyprland
import "Aether"

// Global shortcuts exposed to Hyprland. Bind them with:
//   bind = SUPER, D, global, aether:launcher
// Only the shell registers these; prefer one shell instance per session.
QtObject {
    id: root

    function focusAnd(name) {
        if (Hyprland.focusedMonitor)
            UiState.screenName = Hyprland.focusedMonitor.name;
        UiState.open(name);
    }

    property GlobalShortcut launcher: GlobalShortcut {
        appid: "aether"
        name: "launcher"
        description: "Open the AETHER launcher"
        triggerDescription: "Super+D"
        onPressed: root.focusAnd("launcher")
    }

    property GlobalShortcut dashboard: GlobalShortcut {
        appid: "aether"
        name: "dashboard"
        description: "Open the AETHER control centre"
        triggerDescription: "Super+A"
        onPressed: root.focusAnd("dashboard")
    }

    property GlobalShortcut notifications: GlobalShortcut {
        appid: "aether"
        name: "notifications"
        description: "Open the AETHER notification centre"
        triggerDescription: "Super+N"
        onPressed: root.focusAnd("notifications")
    }

    property GlobalShortcut quickSettings: GlobalShortcut {
        appid: "aether"
        name: "quick-settings"
        description: "Open AETHER quick settings"
        triggerDescription: "Super+S"
        onPressed: root.focusAnd("quickSettings")
    }

    property GlobalShortcut power: GlobalShortcut {
        appid: "aether"
        name: "power"
        description: "Open the AETHER power menu"
        triggerDescription: "Super+Escape"
        onPressed: root.focusAnd("power")
    }

    property GlobalShortcut settings: GlobalShortcut {
        appid: "aether"
        name: "settings"
        description: "Open AETHER Settings"
        onPressed: Quickshell.execDetached(["aether", "settings"])
    }

    property GlobalShortcut music: GlobalShortcut {
        appid: "aether"
        name: "music"
        description: "Open AETHER Music"
        onPressed: Quickshell.execDetached(["aether", "music"])
    }

    property GlobalShortcut monitor: GlobalShortcut {
        appid: "aether"
        name: "monitor"
        description: "Open AETHER System Monitor"
        onPressed: Quickshell.execDetached(["aether", "monitor"])
    }

    property GlobalShortcut files: GlobalShortcut {
        appid: "aether"
        name: "files"
        description: "Open AETHER Files"
        onPressed: Quickshell.execDetached(["aether", "files"])
    }
}
