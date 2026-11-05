---
title: Features
---

# Features

AETHER brings a cohesive desktop experience with the following core features:

## Design

- Material You‑inspired colors with dynamic accent extraction
- Rounded corners and translucency
- Dark‑first theme with support for light and AMOLED variants
- Consistent typography (Inter, Inter Display, JetBrains Mono)

## Functionality

- **Shell**: Quickshell bar, launcher, dashboard, notifications
- **Applications**: Settings, Music, System Monitor, Files, Wallpaper, Power Menu
- **Integration**: Hyprland visual settings, global shortcuts, desktop entries
- **Installer**: Rust + Ratatui TUI with dry‑run, backups, repair and uninstall support
- **Website**: Astro + TypeScript + Tailwind, fully subpath‑safe for GitHub Pages

## System Integration

- Hyprland compositor (managed include with timestamped backups)
- PipeWire, NetworkManager, BlueZ, brightnessctl, hyprsunset
- MPRIS media control, UPower power profiles
- Real‑time system stats, weather, calendar events

## Developer Experience

- Monorepo with independently buildable `shell/`, `apps/`, `installer/`, `website/`
- Shared contracts via JSON configuration and theme format
- Unit tests for installer, shell QML parsing, and website typecheck
- Semantic versioning, checksums, and GitHub Actions CI
