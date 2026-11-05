# Changelog

## v1.0.0 (2026‑11‑05)

**Initial Release**

### Added

- Complete desktop shell with Quickshell bar, launcher, dashboard and notifications
- Seven built‑in themes (AETHER Dark, Light, AMOLED, Midnight, Lavender, Ocean, Forest)
- Settings app with Appearance, Bar, Dashboard, Notifications, Sound, Network, Bluetooth, Power, Hyprland, About pages
- First‑party applications: Settings, Music, System Monitor, Files, Wallpaper, Power Menu
- Rust installer with TUI, dry‑run, backups, repair and uninstall support
- Astro website with all required pages and base‑path‑safe links
- Documentation (installation, themes, widgets, FAQ, limitations, contributing, changelog)
- Helper scripts: `aether`, `aether-hyprland`, `aether-stats`, `aether-terminal`, `aether-wallpaper`
- Hyprland integration (managed include with timestamped backups)
- Version detection via `Config.aetherVersion`

### Changed

- Configuration schema v1, widget layout v1
- All QML files formatted with `qmlformat -n`
- Installer uses atomic writes and timestamped backups
- Website built with Astro + TypeScript + Tailwind
- Installer checks for unsupported distributions and warns

### Fixed

- Bug fixes in Theme resolution and notification handling
- Hyprland include generation consistency

## Earlier versions

Earlier development versions are tracked in git history. For completeness, the changelog will be updated for each major release.
