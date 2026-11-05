# Manual Install

A detailed step‑by‑step guide for installing AETHER from source without the installer.

## Prerequisites

- Arch Linux (≥ 2019.06)
- Rust toolchain (1.99.1) at `~/.cargo/bin`
- Node.js v22.14.0 at `~/.local/opt/node` (optional, only needed for the website)
- sudo access (optional, required only for system package installation)

## Build Installer

```bash
cd /path/to/AETHER
make build-installer    # cargo build --release --manifest-path installer/Cargo.toml
```

This creates `installer/target/release/aether-installer`.

## Install to User Prefix

```bash
cd /path/to/AETHER
make install-user      # copies to ~/.local, creates ~/.local/bin/aether
```

The installer does not require root. It copies:

- Shell, apps, themes, config defaults into `~/.local/share/aether`
- Helper scripts into `~/.local/share/aether/scripts`
- Configuration template into `~/.config/aether/config.json`
- Desktop entries and application icon into standard XDG locations

## Start AETHER

Start the shell:

```bash
aether shell
```

Or add `exec-once = aether shell` to your Hyprland config.

Open applications:

```bash
aether settings   # Settings, themes, wallpaper, bar, dashboard, notifications, etc.
aether music      # MPRIS player
aether monitor    # System monitor
aether files      # File browser
aether wallpaper  # Wallpaper picker
aether power      # Power menu (lock, suspend, logout, shutdown)
aether launcher   # Launcher
```

## System Packages (Optional)

If you want the installer to automatically install missing Arch packages, run:

```bash
aether-installer --dry-run --force-unsupported
```

Then confirm. The installer uses `sudo -n pacman`; you must have cached sudo credentials (`sudo -v`).

## Update AETHER

To update an existing installation, run the installer again. It will back up existing configuration, merge new defaults and reinstall program files.
