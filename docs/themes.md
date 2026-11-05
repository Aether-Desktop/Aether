# Themes

AETHER includes seven built‑in themes that define the visual style of the desktop.

## List of Themes

| Theme | Variant | Primary | Secondary | Surface | Background |
|-------|---------|---------|-----------|---------|------------|
| AETHER Dark | dark | #A99BFF | #6FE7DD | #12151D | #0A0C11 |
| AETHER Light | light | #5B4BD6 | #00796F | #FFFFFF | #F4F2FA |
| AETHER AMOLED | dark | #C3B5FF | #7FF5E9 | #060708 | #000000 |
| AETHER Midnight | dark | #7FA6FF | #8FE3FF | #0E1420 | #070B14 |
| AETHER Lavender | dark | #D9B8FF | #FFC6E5 | #191322 | #120E18 |
| AETHER Ocean | dark | #5FD7D0 | #8CC9FF | #081A20 | #041014 |
| AETHER Forest | dark | #9BE6A8 | #E4D98B | #0E1A13 | #08110C |

## Importing and Exporting

Themes are JSON files and can be imported/exported from Settings. To export, open **AETHER Settings → Appearance → Themes → Export**. To import, paste the JSON into **AETHER Settings → Appearance → Themes → Import**.

## Dynamic Accent Extraction

AETHER uses Quickshell's `ColorQuantizer` to extract a dominant color from the current wallpaper and map it to the `primary` role of the active theme. This allows the desktop to adapt its accent color to the chosen wallpaper.

The extracted accent is stored in `~/.config/aether/theme.json` as `accentOverride`.

## Theme Development

Add a new theme by creating a JSON file in `themes/` with the following structure (see `themes/aether-dark.json` for reference):

- `$schema`: URL to the theme schema
- `schemaVersion`: 1
- `id`: unique identifier (lowercase, hyphen‑separated)
- `name`: display name
- `author`: optional author string
- `version`: theme version (semantic)
- `variant`: "dark" or "light"
- `description`: brief description
- `colors`: semantic roles (primary, secondary, surface, background, etc.)
- `radii`: size scales (xs, sm, md, lg, xl, full)
- `spacing`: spacing scales (xs, sm, md, lg, xl, xxl)
- `typography`: family, displayFamily, monoFamily, scale
- `effects`: blur, blurSize, opacity, borderOpacity, shadow, animationScale

Themes are validated by the installer and by the website’s theme preview system.

## Theme Preview

The **AETHER Settings → Appearance → Theme** page includes a preview pane that renders the theme’s background, accent, and UI components. The preview system shows the colors and radii as defined in the theme JSON.
