<div align="center">

<img src="assets/branding/aether-logo.svg" alt="AETHER" width="420" />

### Your desktop. Your atmosphere. Your AETHER.

A complete, modular Linux desktop ecosystem built on **Hyprland**, **Quickshell**, and **Qt Quick**.

[Website](https://aether-desktop.github.io/AETHER/) ·
[Documentation](docs/) ·
[Installing](docs/installation.md) ·
[Contributing](CONTRIBUTING.md) ·
[License](LICENSE)

</div>

---

AETHER is more than a dotfiles repository. It is a full desktop experience: a custom
Quickshell desktop shell, a suite of first-party applications, a theme engine with
wallpaper-derived accent colors, a plugin/widget architecture, a safe Rust TUI
installer, and a fast Astro website — all sharing one visual language.

> **Project status:** AETHER is an ambitious first release. The installer and website
> are built and tested in CI; the shell and applications are implemented against the
> documented Quickshell 0.3.x API and validated for QML syntax, but require a live
> Hyprland/Wayland session with Quickshell installed for full end-to-end verification.
> See [Verified vs. unverified](#verified-vs-unverified) and
> [docs/limitations.md](docs/limitations.md). We do not pretend otherwise.

## Highlights

| | |
|---|---|
| **AETHER Bar** | Floating or docked top bar, workspaces, active window, clock, media, tray, status, quick settings. |
| **Dashboard** | Expandable control center with clock, calendar, weather, media, system statistics and widgets. |
| **Launcher** | Fast keyboard-first app search, favorites, recents, categories, fuzzy matching. |
| **Notifications** | Real notification daemon with history, cards, DND and grouping. |
| **Quick Settings** | Material You-inspired toggles wired to NetworkManager, BlueZ and PipeWire. |
| **Theme engine** | Seven built-in themes, dynamic accent extraction, live previews, import/export. |
| **Apps** | Settings, Music, System Monitor, Wallpaper, Power Menu and File Browser. |
| **Widgets** | Declarative widget API with safe, data-only plugin manifests. |
| **TUI installer** | Rust + Ratatui, system detection, profiles, component review, backups, repair, uninstall, dry-run. |
| **Website** | Astro + TypeScript + Tailwind, accessible, responsive, GitHub Pages ready. |

## Screenshots

The AETHER website ships a **schematic preview** system instead of fabricated
"screenshots". Every placeholder is explicitly labelled as a design preview until a
contributor supplies a real capture in `assets/screenshots/` (see
[`assets/screenshots/README.md`](assets/screenshots/README.md)). This is deliberate:
we will not present mockups as real application captures.

## Requirements

- **Arch Linux** (first-class, the only officially supported distribution today)
- Wayland session with **Hyprland ≥ 0.40**
- **Quickshell ≥ 0.2** (`quickshell` package or built from source)
- PipeWire + WirePlumber (audio), NetworkManager (network), BlueZ (Bluetooth)
- A Nerd Font or Inter (recommended) for typography

Fedora, openSUSE and NixOS are **not** claimed as supported. The installer's package
abstraction has extension points for them; see [docs/limitations.md](docs/limitations.md).

## Installation

### Quick install (recommended)

```bash
git clone https://github.com/aether-desktop/AETHER.git
cd AETHER
./install.sh
```

`install.sh` locates the compiled TUI installer, or builds it from source when Cargo is
available, then launches it. Nothing is installed without confirmation, and existing
configuration is backed up first.

### Release binary

Download `aether-installer-x86_64-linux` from
[Releases](https://github.com/aether-desktop/AETHER/releases), verify `SHA256SUMS`,
then run it:

```bash
sha256sum -c SHA256SUMS --ignore-missing
chmod +x aether-installer-x86_64-linux
./aether-installer-x86_64-linux
```

### Manual / development install

```bash
git clone https://github.com/aether-desktop/AETHER.git
cd AETHER
make build-installer
make install-user        # copies to ~/.local, never requires root
```

Start Hyprland, then:

```bash
aether shell            # Quickshell shell
aether settings         # AETHER Settings
aether launcher         # standalone launcher
```

Or add to your Hyprland config:

```ini
exec-once = aether shell
```

Detailed guides: [installation](docs/installation.md),
[manual installation](docs/manual-install.md), [themes](docs/themes.md),
[widgets](docs/widget-development.md).

## Configuration

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

- [Configuration reference](docs/configuration.md)
- [Theme documentation](docs/themes.md)
- [Widget documentation](docs/widgets.md)

## The application suite

| Application | Command | Purpose |
|---|---|---|
| AETHER Settings | `aether settings` | Appearance, themes, wallpaper, bar, dashboard, notifications, widgets, animations, Hyprland, keybindings, apps, monitors, system, about |
| AETHER Music | `aether music` | MPRIS player with artwork, seek, volume |
| AETHER System Monitor | `aether monitor` | CPU, RAM, GPU, disk, network, temperature, battery |
| AETHER Wallpaper | `aether wallpaper` | Gallery, preview, set wallpaper, extract accent |
| AETHER Power Menu | `aether power` | Lock, suspend, logout, reboot, shutdown with confirmation |
| AETHER File Browser | `aether files [path]` | Navigation, search, bookmarks, previews |
| AETHER Launcher | `aether launcher` | Standalone fuzzy launcher |

## Themes

AETHER Dark · AETHER Light · AETHER AMOLED · AETHER Midnight · AETHER Lavender ·
AETHER Ocean · AETHER Forest.

Every theme declares semantic color roles, radii, typography, blur and opacity. Dynamic
accent extraction uses Quickshell's `ColorQuantizer` on the current wallpaper. Themes are
JSON files and can be imported/exported from Settings. See [docs/themes.md](docs/themes.md).

## Architecture

```
AETHER/
├── shell/        Quickshell desktop shell (QML) + shared design system
├── apps/         First-party Quickshell applications
├── installer/    Rust + Ratatui TUI installer
├── website/      Astro + TypeScript + Tailwind site
├── hypr/         Hyprland configuration and scripts
├── themes/       Built-in theme definitions
├── config/       Default user configuration
├── scripts/      aether launcher, theme tools, release helpers
├── assets/       Branding and real-screenshot drop-in location
├── docs/         User and developer documentation
└── install.sh    Bootstrap for the TUI installer
```

The shell, installer and website are independently buildable. Shared contracts are the
JSON configuration schema and the theme format; neither the installer nor the website
parses QML.

## Building from source

```bash
make build-installer     # cargo build --release --manifest-path installer/Cargo.toml
make build-website       # npm ci && npm run build --prefix website
make check               # shell syntax, rust tests, website typecheck/build
```

Individual components:

```bash
cd installer && cargo test && cargo build --release
cd website   && npm install && npm run dev
qs -p shell/shell.qml       # run the shell from the repo
```

## Verified vs. unverified

Verified in this repository (automated):

- Installer compiles, unit/integration tests pass, TUI state machine and filesystem
  operations tested (including backups, dry-run, repair and uninstall safety).
- Website type-checks, builds as static output, and builds correctly for a GitHub Pages
  subpath (link/asset checks in CI).
- All QML files parse/format cleanly (`qmlformat`), and the shell's pure-QML logic
  passes syntax validation.
- Hyprland configuration uses valid syntax for Hyprland 0.57 and does not overwrite
  user files.

Unverified here (needs a live Wayland session with Quickshell):

- Pixel-level shell rendering, bar/window positioning across monitors, live PipeWire /
  UPower / MPRIS / notification behavior.
- Hyprland IPC-driven workspace switching in a running compositor.
- System monitor GPU sensors on non-AMD/NVIDIA hardware.

If something is broken on your machine, please open an issue with your
`quickshell --version`, `hyprctl version`, distribution and logs from
`journalctl --user -u aether-shell`. Honest reports are welcome.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `quickshell: command not found` | Install Quickshell, then `aether doctor` |
| Bar missing on second monitor | Settings → Monitors, enable the monitor, or `aether shell --reload` |
| No audio controls | Ensure PipeWire + WirePlumber are running (`systemctl --user status pipewire`) |
| Notifications not appearing | Ensure no other daemon owns `org.freedesktop.Notifications` |
| Theme not applied everywhere | `aether reload`, or check `~/.config/aether/theme.json` |
| Installer fails | Re-run with `--debug`; logs at `~/.local/state/aether/install.log` |

More: [docs/troubleshooting.md](docs/troubleshooting.md).

## Contributing

We welcome contributions. Start with [CONTRIBUTING.md](CONTRIBUTING.md), read the
[design system](docs/design-system.md), and run `make check` before opening a PR.
Security issues: see [SECURITY.md](SECURITY.md).

## License

AETHER is free software under the [MIT License](LICENSE). Branding assets are also MIT
licensed. Third-party trademarks belong to their respective owners.

---

<div align="center">
<sub>Built with care for people who like their desktops to feel like home.</sub>
</div>
