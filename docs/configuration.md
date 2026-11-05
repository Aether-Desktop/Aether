# Configuration

This document describes the configuration files and options used by AETHER.

## User Configuration

AETHER stores user state in `~/.config/aether/`:

```
~/.config/aether/
├── config.json        # bar, dashboard, animations, behavior
├── theme.json         # active theme + accent overrides
├── widgets.json       # enabled/ordered widget instances
├── favorites.json     # launcher favorites
└── themes/            # imported themes
```

The shell, apps and installer all read the same files. Edits are picked up live.

### config.json schema

The configuration is a JSON object with the following top‑level keys (see `config/config.default.json` for defaults):

- `general`: language, startup apps
- `bar`: position, height, media, tray, etc.
- `dashboard`: weather, calendar, media, stats, quick actions
- `notifications`: Do Not Disturb, history size, grouping, position
- `quickSettings`: toggles (wifi, bluetooth, night light, etc.)
- `launcher`: search options, favorites, recent apps
- `animations`: enabled, speed, reduced motion
- `appearance`: theme, wallpaper, font scale, radius scale, transparency, blur
- `hyprland`: visual settings (gaps, borders, rounding, blur, shadows)
- `monitors`: locked profiles
- `updates`: auto‑check channel

### theme.json

Stores the user‑selected theme ID and accent override.

### widgets.json

Defines the enabled/ordered widget instances for the bar/dashboard.

### favorites.json and recent apps

Launcher favorites are stored separate for convenience.

## Theme Format

Themes are JSON files in `themes/` (seven built‑in themes). Each theme declares semantic color roles, radii, typography, blur and opacity. Dynamic accent extraction uses Quickshell's `ColorQuantizer` on the current wallpaper.

See `themes/index.json` for theme metadata.

## Hyprland Integration

AETHER generates a static Hyprland include (`~/.config/hypr/aether/generated.conf`) that is sourced from `~/.config/hypr/hyprland.conf` (if managed). Visual settings are derived from the active theme and user configuration.

The installer can enable Hyprland management (default off). Once enabled, run `aether hyprland --apply` or start the installer with `--manage-hyprland` to add the include.

## Configuration Live Updates

Changes to `config.json` are watched by Quickshell and applied instantly (e.g., theme switch, bar visibility). The installer merges user keys with defaults, preserving unknown keys.

## Migration

When AETHER upgrades, the installer backs up the existing `config.json`, merges new defaults, and writes back. Unknown user keys are preserved.
