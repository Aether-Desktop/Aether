---
title: Widgets
type: doc
pubDate: 2024-01-01
---

# Widgets

The AETHER bar supports extensible widgets:

- Clock
- Calendar
- Weather
- Media playback
- System stats
- Battery
- Network
- Workspace overview

Widget layout is stored in `~/.config/aether/widgets.json` and can be reordered via the Settings → Widgets page.

## Development

Add a new widget by creating a QML component that follows the shared `Aether` design system. Update `config/widgets.default.json` to enable it by default.
