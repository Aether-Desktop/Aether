# Widgets

Widgets are reusable UI components that populate the AETHER bar and dashboard. Each widget is a QML component that follows the shared `Aether` design system.

## Widget Catalog

The following widgets are included by default:

### Clock
Displays the current time and date. Can show seconds, timezones, and date formats.

### Calendar
Shows a monthly calendar with events (if enabled in Settings → Dashboard).

### Weather
Fetches data from Open‑Meteo (configurable lat/lon). Shows temperature, conditions, and forecasts.

### Media
Controls PipeWire playback and displays artwork from MPRIS players.

### System Stats
Displays CPU, RAM, GPU, disk, network and temperature usage. Includes a history chart.

### Battery
Shows charge level, remaining time, and power source.

### Network
Shows Wi‑Fi and wired network status.

### Bluetooth
Shows Bluetooth device list and connection status.

### Workspace Overview
Visual overview of Hyprland workspaces and active windows.

## Widget Layout

Widgets are arranged in columns (left/right) via `~/.config/aether/widgets.json`. The layout is editable in **AETHER Settings → Widgets**.

```json
{
  "schemaVersion": 1,
  "layout": [
    { "id": "clock", "type": "clock", "enabled": true, "column": "left", "order": 0 },
    { "id": "calendar", "type": "calendar", "enabled": true, "column": "left", "order": 1 },
    { "id": "weather", "type": "weather", "enabled": true, "column": "left", "order": 2 },
    { "id": "media", "type": "media", "enabled": true, "column": "left", "order": 3 },
    { "id": "stats", "type": "systemStats", "enabled": true, "column": "right", "order": 0 },
    { "id": "battery", "type": "battery", "enabled": true, "column": "right", "order": 1 },
    { "id": "network", "type": "network", "enabled": true, "column": "right", "order": 2 },
    { "id": "workspaces", "type": "workspaceOverview", "enabled": true, "column": "right", "order": 3 }
  ]
}
```

## Widget Development

### Prerequisites

- Knowledge of Qt Quick and QML.
- Familiarity with Quickshell and its import paths (`shell/Aether`).
- Understanding of the AETHER design system (colors, radii, typography).

### Creating a New Widget

1. **Component location**: Place the QML file in `apps/<widget-name>/` (e.g., `apps/myweather/`). The component must export a `root` item.
2. **Import path**: Ensure the component is accessible via `shell/Aether/` or a relative import from apps.
3. **Properties**: Follow the existing widget patterns (e.g., `enabled`, `config`, `data`).
4. **Integration**: Add an entry to `config/widgets.default.json` to enable it by default. The entry includes `id`, `type`, `column`, `order`, and optional `options`.
5. **Testing**: Validate QML syntax with `qmlformat -n apps/<widget-name>/widget.qml`.

### Widget API

Widgets receive configuration from `~/.config/aether/widgets.json`. The configuration is parsed by the shell and passed as `config` property to the widget root.

Example QML property:

```qml
property var config: ({}) { }
```

Data is provided via Quickshell services (e.g., `System.qml` for stats, `Weather.qml` for weather). Widgets can bind to these singletons.

## Extensibility

Widgets can be extended by third‑party developers. To contribute a widget, create a PR that adds the widget to the repository and updates `config/widgets.default.json`.

## Limitations

- Widgets are limited to the bar/dashboard columns defined in `widgets.json`.
- Some system data may be unavailable in sandboxed environments (e.g., no network access).
