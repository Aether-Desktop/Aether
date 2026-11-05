---
title: Changelog
---

# Changelog

## v1.0.0 (2026‑11‑05)

Initial public release.

### Added

- Complete desktop shell with Quickshell
- Seven built‑in themes and a theme engine
- Settings app with appearance, bar, dashboard, notifications, system, Hyprland and about pages
- First‑party applications: Music, System Monitor, Files, Wallpaper, Power Menu
- Rust installer with TUI, dry‑run, backups, repair and uninstall support
- Astro website with all required pages
- Documentation (installation, themes, widgets, FAQ)
- Hyprland integration (managed include)
- Helper scripts: `aether`, `aether-hyprland`, `aether-stats`, `aether-terminal`, `aether-wallpaper`

### Changed

- Configuration schema v1, widget layout v1
- All QML files formatted with `qmlformat -n`
- Installer uses atomic writes and timestamped backups

### Fixed

- Bug fixes in Theme resolution and notification handling

## Earlier versions

Earlier development versions are documented in the git history.
