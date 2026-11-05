pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "Util.js" as Util

// AETHER theme engine.
// Resolution order: user theme (~/.config/aether/themes), bundled theme, safe fallback.
// A wallpaper-derived accent, or an explicit user accent, overrides the palette primary.
QtObject {
    id: root

    readonly property var fallbackPalette: ({
        id: "aether-dark",
        name: "AETHER Dark",
        variant: "dark",
        colors: {
            background: "#0A0C11", surface: "#12151D", surfaceContainer: "#181C26",
            surfaceContainerHigh: "#202533", surfaceContainerHighest: "#2A3040",
            onSurface: "#E8EAF2", onSurfaceVariant: "#A7AEC3", outline: "#394154",
            primary: "#A99BFF", onPrimary: "#17112E", primaryContainer: "#362B66",
            onPrimaryContainer: "#E4DEFF", secondary: "#6FE7DD", onSecondary: "#062B28",
            tertiary: "#FFB4C8", error: "#FFB4AB", warning: "#FFD28A", success: "#8BE3A2",
            glow: "#8C7BFF", wallpaperTint: "#141827", shadow: "#000000", scrim: "#000000"
        },
        radii: { xs: 6, sm: 10, md: 16, lg: 22, xl: 28, full: 999 },
        spacing: { xs: 4, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32 },
        typography: { family: "Inter", displayFamily: "Inter Display", monoFamily: "JetBrains Mono", scale: 1.0 },
        effects: { blur: true, blurSize: 36, opacity: 0.86, borderOpacity: 0.12, shadow: true, animationScale: 1.0 }
    })

    property var palette: root.fallbackPalette
    property var themeIndex: []
    property color wallpaperAccent: "transparent"
    property bool userThemeActive: false

    readonly property string themeId: Config.themeId
    readonly property bool isLight: (root.palette.variant || "dark") === "light"
    readonly property bool isAmoled: root.themeId === "aether-amoled"

    readonly property color accentOverride: Config.appearance.accentOverride
        ? Config.appearance.accentOverride : "transparent"
    readonly property color dynamicAccent: (Config.appearance.wallpaperAccent === true
        && root.wallpaperAccent.a > 0) ? root.wallpaperAccent : "transparent"
    readonly property color accent: root.accentOverride.a > 0 ? root.accentOverride
        : (root.dynamicAccent.a > 0 ? root.dynamicAccent : root.col("primary"))

    function col(name) {
        const c = root.palette.colors || root.fallbackPalette.colors;
        return c[name] !== undefined ? c[name] : root.fallbackPalette.colors[name];
    }

    // ---- Semantic color roles ----
    readonly property color background: root.col("background")
    readonly property color surface: root.col("surface")
    readonly property color surfaceContainer: root.col("surfaceContainer")
    readonly property color surfaceContainerHigh: root.col("surfaceContainerHigh")
    readonly property color surfaceContainerHighest: root.col("surfaceContainerHighest")
    readonly property color onSurface: root.col("onSurface")
    readonly property color onSurfaceVariant: root.col("onSurfaceVariant")
    readonly property color outline: root.col("outline")
    readonly property color primary: root.accent
    readonly property color onPrimary: Util.onColor(root.accent)
    readonly property color primaryContainer: (root.accentOverride.a > 0 || root.dynamicAccent.a > 0)
        ? Util.mix(root.accent, root.surface, root.isLight ? 0.82 : 0.76)
        : root.col("primaryContainer")
    readonly property color onPrimaryContainer: (root.accentOverride.a > 0 || root.dynamicAccent.a > 0)
        ? (root.isLight ? Util.mix(root.accent, "#000000", 0.55) : Util.mix(root.accent, "#FFFFFF", 0.55))
        : root.col("onPrimaryContainer")
    readonly property color secondary: root.col("secondary")
    readonly property color onSecondary: root.col("onSecondary")
    readonly property color tertiary: root.col("tertiary")
    readonly property color error: root.col("error")
    readonly property color warning: root.col("warning")
    readonly property color success: root.col("success")
    readonly property color glow: root.dynamicAccent.a > 0 ? root.dynamicAccent : root.col("glow")
    readonly property color shadow: root.col("shadow")
    readonly property color scrim: root.col("scrim")
    readonly property color wallpaperTint: root.col("wallpaperTint")

    readonly property color glass: Util.alpha(root.surface,
        Util.clamp(Config.appearance.transparency !== undefined ? Config.appearance.transparency
            : (root.palette.effects ? root.palette.effects.opacity : 0.86), 0.35, 1.0))
    readonly property color glassHigh: Util.alpha(root.surfaceContainer,
        Util.clamp((Config.appearance.transparency || 0.86) + 0.06, 0.4, 1.0))
    readonly property color hover: Util.alpha(root.onSurface, 0.07)
    readonly property color pressed: Util.alpha(root.onSurface, 0.12)
    readonly property color selected: Util.alpha(root.primary, 0.16)
    readonly property color hairline: Util.alpha(root.outline, 0.45)

    // ---- Shape ----
    readonly property real radiusScale: Config.appearance.radiusScale || 1.0
    function radius(name) {
        const r = (root.palette.radii || root.fallbackPalette.radii);
        return Math.round((r[name] !== undefined ? r[name] : 16) * root.radiusScale);
    }
    readonly property int radiusXs: root.radius("xs")
    readonly property int radiusSm: root.radius("sm")
    readonly property int radiusMd: root.radius("md")
    readonly property int radiusLg: root.radius("lg")
    readonly property int radiusXl: root.radius("xl")
    readonly property int radiusFull: 999

    readonly property var spacing: root.palette.spacing || root.fallbackPalette.spacing
    function space(name) { return root.spacing[name] !== undefined ? root.spacing[name] : 12; }

    // ---- Type ----
    readonly property string fontFamily: Config.appearance.fontFamily
        || (root.palette.typography ? root.palette.typography.family : "Inter") || "Inter"
    readonly property string fontDisplay: root.palette.typography
        ? (root.palette.typography.displayFamily || root.fontFamily) : root.fontFamily
    readonly property string fontMono: root.palette.typography
        ? (root.palette.typography.monoFamily || "JetBrains Mono") : "JetBrains Mono"
    readonly property real fontScale: Config.appearance.fontScale || 1.0
    function fs(px) { return Math.round(px * root.fontScale); }

    // ---- Motion ----
    readonly property int durationFast: Math.round(120 * Config.animationScale)
    readonly property int durationNormal: Math.round(220 * Config.animationScale)
    readonly property int durationSlow: Math.round(380 * Config.animationScale)
    readonly property int easing: Easing.OutCubic
    readonly property int easingEmphasized: Easing.OutQuint

    // ---- Wallpaper + dynamic color ----
    readonly property string wallpaperPath: Config.wallpaperPath
    readonly property url wallpaperUrl: Util.fileUrl(root.wallpaperPath)

    property ColorQuantizer quantizer: ColorQuantizer {
        id: quantizerObject
        source: Config.appearance.wallpaperAccent === true ? root.wallpaperUrl : ""
        depth: 4
        rescaleSize: 56
        onColorsChanged: root.pickAccent(colors)
    }

    function pickAccent(colors) {
        if (!colors || colors.length === 0) {
            root.wallpaperAccent = "transparent";
            return;
        }
        let best = null;
        let bestScore = -1;
        for (let i = 0; i < colors.length; i++) {
            const c = colors[i];
            if (c.a === 0) continue;
            const sat = c.hsvSaturation;
            const val = c.hsvValue;
            if (sat < 0.24 || val < 0.22) continue;
            let score = sat * 0.76 + val * 0.24;
            // Keep light themes legible: avoid near-white accents.
            if (root.isLight && val > 0.78) score -= 0.25;
            // Slightly prefer mid-bright colors for glowing accents on dark surfaces.
            if (!root.isLight && val > 0.55 && val < 0.92) score += 0.08;
            if (score > bestScore) {
                bestScore = score;
                best = c;
            }
        }
        if (!best) {
            root.wallpaperAccent = "transparent";
            return;
        }
        // Normalise so accents remain visible on all themes.
        const targetVal = root.isLight ? 0.52 : 0.78;
        root.wallpaperAccent = Qt.hsva(best.hsvHue,
            Util.clamp(best.hsvSaturation, 0.3, 0.85), targetVal, 1.0);
    }

    property Timer accentDebounce: Timer {
        interval: 120
        repeat: false
        onTriggered: root.pickAccent(root.quantizer.colors)
    }

    readonly property var availableThemes: root.themeIndex.length > 0 ? root.themeIndex : [
        { id: "aether-dark", name: "AETHER Dark", variant: "dark" },
        { id: "aether-light", name: "AETHER Light", variant: "light" },
        { id: "aether-amoled", name: "AETHER AMOLED", variant: "dark" },
        { id: "aether-midnight", name: "AETHER Midnight", variant: "dark" },
        { id: "aether-lavender", name: "AETHER Lavender", variant: "dark" },
        { id: "aether-ocean", name: "AETHER Ocean", variant: "dark" },
        { id: "aether-forest", name: "AETHER Forest", variant: "dark" }
    ]

    function themeMeta(id) {
        for (let i = 0; i < root.availableThemes.length; i++)
            if (root.availableThemes[i].id === id) return root.availableThemes[i];
        return null;
    }

    property FileView indexFile: FileView {
        path: Config.themesDir + "/index.json"
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                const doc = JSON.parse(indexFile.text());
                root.themeIndex = doc.themes || [];
            } catch (e) {
                console.warn("AETHER: theme index invalid:", e);
            }
        }
    }

    // A user copy in ~/.config/aether/themes takes precedence, enabling import.
    property FileView userThemeFile: FileView {
        path: Config.userThemesDir + "/" + root.themeId + ".json"
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: root._applyTheme(userThemeFile.text(), true)
        onFileChanged: userThemeFile.reload()
        onLoadFailed: {
            root.userThemeActive = false;
            if (bundledThemeFile.path !== Config.themesDir + "/" + root.themeId + ".json")
                bundledThemeFile.path = Config.themesDir + "/" + root.themeId + ".json";
            else
                bundledThemeFile.reload();
        }
    }

    property FileView bundledThemeFile: FileView {
        path: ""
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: root._applyTheme(bundledThemeFile.text(), false)
        onFileChanged: bundledThemeFile.reload()
        onLoadFailed: {
            console.warn("AETHER: theme '" + root.themeId + "' not found; using AETHER Dark");
            root.palette = root.fallbackPalette;
        }
    }

    onThemeIdChanged: {
        root.palette = root.fallbackPalette;
        root.userThemeActive = false;
        bundledThemeFile.path = "";
        userThemeFile.reload();
    }

    function _applyTheme(text, user) {
        try {
            const doc = JSON.parse(text);
            if (!doc || !doc.colors) throw new Error("missing colors object");
            root.palette = doc;
            root.userThemeActive = user === true;
        } catch (e) {
            console.warn("AETHER: invalid theme file:", e);
            root.palette = root.fallbackPalette;
            root.userThemeActive = false;
        }
    }

    // Load an arbitrary theme file for the Settings preview without persisting it.
    function previewThemeFile(path) {
        previewFile.path = path;
    }

    property FileView previewFile: FileView {
        path: ""
        blockLoading: true
        printErrors: false
        onLoaded: root._applyTheme(previewFile.text(), true)
        onLoadFailed: console.warn("AETHER: could not preview theme", previewFile.path)
    }

    function endPreview() {
        root.palette = root.fallbackPalette;
        root.userThemeActive = false;
        bundledThemeFile.path = "";
        userThemeFile.reload();
    }
}
