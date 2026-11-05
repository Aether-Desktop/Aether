pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "Util.js" as Util

// Persistent AETHER configuration. One source of truth for the shell and every app.
// Writes are debounced and atomic; unknown user keys survive round-trips.
QtObject {
    id: root

    readonly property string installRoot: String(Quickshell.shellDir || "").replace(/\/$/, "") + "/.."
    readonly property string aetherVersion: "1.0.0"
    readonly property string repositoryUrl: "https://github.com/aether-desktop/AETHER"
    readonly property string websiteUrl: "https://aether-desktop.github.io/AETHER/"
    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/aether"
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/aether"
    readonly property string configFile: root.configDir + "/config.json"
    readonly property string themesDir: root.installRoot + "/themes"
    readonly property string userThemesDir: root.configDir + "/themes"
    readonly property string assetsDir: root.installRoot + "/assets"

    // Minimal hard fallback used only if the bundled defaults are missing or corrupt.
    // The authoritative defaults live in config/config.default.json.
    readonly property var hardDefaults: ({
        schemaVersion: 1,
        bar: { enabled: true, position: "top", mode: "floating", height: 44, margin: 8, exclusive: false,
               autoHide: false, showWorkspaces: true, workspaceCount: 6, showActiveWindow: true,
               showClock: true, clockFormat: "HH:mm", clockSeconds: false, showMedia: true,
               showTray: true, showBattery: true, showNetwork: true, showBluetooth: true,
               showVolume: true, showNotifications: true, monitors: [] },
        dashboard: { enabled: true, weather: { enabled: true, latitude: null, longitude: null, units: "metric" },
                     calendar: true, events: true, media: true, stats: true, quickActions: true },
        notifications: { doNotDisturb: false, historySize: 100, timeout: 6000, showBody: true,
                         showImage: true, grouping: true, position: "top-right" },
        quickSettings: { toggles: ["wifi", "bluetooth", "nightLight", "darkMode", "dnd", "powerSaver"] },
        launcher: { width: 640, maxResults: 8, showFavorites: true, showRecent: true,
                    showCategories: true, fuzzy: true, favorites: [], recent: [] },
        animations: { enabled: true, speed: 1.0, reducedMotion: false },
        appearance: { theme: "aether-dark", accentOverride: null,
                      wallpaper: "assets/wallpapers/aether-default.svg", fontFamily: "Inter",
                      fontScale: 1.0, radiusScale: 1.0, transparency: 0.86, blur: true,
                      wallpaperAccent: true, nightLight: false, nightLightTemperature: 4000 },
        hyprland: { manageConfig: false, gapsIn: 5, gapsOut: 12, borderSize: 2, rounding: 16,
                    blur: true, shadows: true, animationPreset: "aether" },
        monitors: { locked: false, profiles: {} },
        updates: { checkOnStart: true, channel: "stable" },
    })

    property var data: Util.clone(root.hardDefaults)
    property var defaults: Util.clone(root.hardDefaults)
    property bool ready: false
    property bool usingBundledDefaults: false
    property bool _writing: false
    property bool _seeded: false

    // ---- Convenience views (recomputed whenever `data` is replaced) ----
    readonly property var general: root.data.general || ({})
    readonly property var bar: root.data.bar || root.hardDefaults.bar
    readonly property var dashboard: root.data.dashboard || root.hardDefaults.dashboard
    readonly property var notifications: root.data.notifications || root.hardDefaults.notifications
    readonly property var quickSettings: root.data.quickSettings || root.hardDefaults.quickSettings
    readonly property var launcher: root.data.launcher || root.hardDefaults.launcher
    readonly property var animations: root.data.animations || root.hardDefaults.animations
    readonly property var appearance: root.data.appearance || root.hardDefaults.appearance
    readonly property var hyprland: root.data.hyprland || root.hardDefaults.hyprland
    readonly property var monitors: root.data.monitors || root.hardDefaults.monitors

    readonly property string themeId: root.appearance.theme || "aether-dark"
    readonly property bool dnd: root.notifications.doNotDisturb === true
    readonly property real animationScale: root.animations.reducedMotion === true ? 0
        : (root.animations.enabled === false ? 0 : 1 / Math.max(0.25, root.animations.speed || 1))
    readonly property string wallpaperPath: {
        const p = root.appearance.wallpaper || "";
        if (!p) return "";
        if (p.indexOf("/") === 0) return p;
        return root.installRoot + "/" + p;
    }

    function get(path, fallback) {
        return Util.getPath(root.data, path, fallback);
    }

    function set(path, value) {
        root.data = Util.setPath(root.data, path, value);
        root.scheduleSave();
    }

    function patch(partial) {
        root.data = Util.deepMerge(root.data, partial);
        root.scheduleSave();
    }

    function toggle(path) {
        root.set(path, !root.get(path, false));
    }

    function setTheme(id) {
        root.set("appearance.theme", id);
    }

    function setAccent(color) {
        const safe = color ? Util.sanitizeColor(color) : null;
        root.set("appearance.accentOverride", safe);
    }

    function addRecent(appId) {
        if (!appId) return;
        const list = (root.launcher.recent || []).filter((x) => x !== appId);
        list.unshift(appId);
        root.set("launcher.recent", list.slice(0, 12));
    }

    function toggleFavorite(appId) {
        if (!appId) return;
        const favs = root.launcher.favorites || [];
        const next = favs.indexOf(appId) === -1 ? favs.concat([appId]) : favs.filter((x) => x !== appId);
        root.set("launcher.favorites", next);
    }

    function scheduleSave() {
        if (!root.ready) return;
        saveTimer.restart();
    }

    function saveNow() {
        if (!root.ready) return;
        saveTimer.stop();
        root._writing = true;
        userFile.setText(JSON.stringify(root.data, null, 2) + "\n");
    }

    function reload() {
        userFile.reload();
    }

    function _onBundledLoaded() {
        try {
            root.defaults = JSON.parse(bundledFile.text());
        } catch (e) {
            console.warn("AETHER: bundled config is not valid JSON:", e);
        }
        if (!root.ready) root._seed(bundledFile.text());
    }

    function _seed(text) {
        if (root._seeded) return;
        root._seeded = true;
        let base = root.hardDefaults;
        try {
            if (text && text.length > 0) base = JSON.parse(text);
        } catch (e) {
            console.warn("AETHER: could not parse default config:", e);
        }
        root.defaults = base;
        root.data = Util.deepMerge(base, {});
        root.usingBundledDefaults = true;
        root.ready = true;
        // First run: materialise the user's config so every app can rely on it.
        root.scheduleSave();
    }

    function _ingest(text) {
        let parsed = ({});
        try {
            parsed = text && text.length > 0 ? JSON.parse(text) : ({});
        } catch (e) {
            console.warn("AETHER: config.json is invalid; falling back to defaults. Details:", e);
            root._seed(bundledFile.text());
            return;
        }
        root.data = Util.deepMerge(root.defaults, parsed);
        root.usingBundledDefaults = false;
        root.ready = true;
        // Persist newly introduced default keys for a stable on-disk schema.
        const mergedText = JSON.stringify(root.data, null, 2) + "\n";
        if (mergedText !== text) root.scheduleSave();
    }

    property Timer saveTimer: Timer {
        interval: 300
        repeat: false
        onTriggered: root.saveNow()
    }

    property FileView bundledFile: FileView {
        path: root.installRoot + "/config/config.default.json"
        blockLoading: true
        printErrors: false
        onLoaded: root._onBundledLoaded()
        onLoadFailed: (error) => {
            console.warn("AETHER: bundled defaults unavailable (" + error + "); using minimal fallback");
            if (!root.ready) root._seed("");
        }
    }

    property FileView userFile: FileView {
        path: root.configFile
        blockLoading: true
        atomicWrites: true
        watchChanges: true
        printErrors: false
        onLoaded: {
            if (!root._writing) root._ingest(userFile.text());
        }
        onLoadFailed: (error) => {
            if (error !== FileViewError.FileNotFound)
                console.warn("AETHER: could not read config (" + error + "); using defaults");
            root._seed(bundledFile.text());
        }
        onFileChanged: {
            if (!root._writing) userFile.reload();
        }
        onSaved: root._writing = false
    }
}
