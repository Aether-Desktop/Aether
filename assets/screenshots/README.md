# Real screenshots

This directory is where **real** AETHER captures live.

The website intentionally renders labelled schematic previews until captures exist.
That is not a placeholder trick: every preview is visibly marked "design preview" so we
never present a mockup as a real application screenshot.

## Naming

```
desktop.png        Full desktop with bar
dashboard.png      Dashboard open
launcher.png       Launcher with search
settings.png       Settings → Appearance
quick-settings.png Quick settings panel
music.png          Music player
notifications.png  Notification centre
```

PNG, 16-bit color, minimum 2560×1440, no personal information, no proprietary wallpapers
unless redistributable. Add the capture to `website/public/screenshots/` and register it
in `website/src/data/screenshots.ts` with `real: true` and a short caption. Update this
file with the contributor credit.

## Capturing safely

```bash
# Hyprland + grim, temporary demo state, then restore your config
grim -o "$(hyprctl monitors -j | jq -r '.[0].name')" desktop.png
```

Use the AETHER demo configuration (`AETHER_DEMO=1 aether shell`) to avoid leaking real
notifications or file names.
