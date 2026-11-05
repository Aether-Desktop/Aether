pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Session actions. Commands are argument arrays; no shell is involved.
QtObject {
    id: root

    readonly property var actions: [
        { id: "lock", label: "Lock", icon: "lock", description: "Lock this session" },
        { id: "suspend", label: "Suspend", icon: "suspend", description: "Suspend to RAM" },
        { id: "logout", label: "Log out", icon: "logout", description: "End the Hyprland session" },
        { id: "reboot", label: "Reboot", icon: "reboot", description: "Restart the computer" },
        { id: "shutdown", label: "Shut down", icon: "shutdown", description: "Power off the computer" }
    ]

    function actionLabel(id) {
        for (let i = 0; i < root.actions.length; i++)
            if (root.actions[i].id === id) return root.actions[i].label;
        return id;
    }

    function confirmLabel(id) {
        return id === "shutdown" ? "Shut down" : id === "reboot" ? "Reboot"
            : id === "logout" ? "Log out" : id === "suspend" ? "Suspend" : "Lock";
    }

    function isDestructive(id) {
        return id === "shutdown" || id === "reboot" || id === "logout";
    }

    function perform(id) {
        switch (id) {
        case "lock":
            Quickshell.execDetached(["loginctl", "lock-session"]);
            break;
        case "suspend":
            Quickshell.execDetached(["systemctl", "suspend"]);
            break;
        case "logout":
            Hyprland.dispatch("exit");
            break;
        case "reboot":
            Quickshell.execDetached(["systemctl", "reboot"]);
            break;
        case "shutdown":
            Quickshell.execDetached(["systemctl", "poweroff"]);
            break;
        case "reload":
            Quickshell.reload(false);
            break;
        case "quit":
            Qt.quit();
            break;
        default:
            console.warn("AETHER: unknown power action", id);
        }
    }
}
