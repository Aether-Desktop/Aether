---
title: Install
---

# Installation Guide

Follow the steps below to install AETHER on your Arch Linux system.

## Step 1: Prepare

- Ensure you have Arch Linux (≥ 2019.06)
- Have sudo access (the installer uses `sudo -n` for package installation)
- Authenticate sudo first if you haven't recently:

```bash
sudo -v
```

## Step 2: Run the Installer

```bash
git clone https://github.com/aether-desktop/AETHER.git
cd AETHER
./install.sh
```

The installer is a TUI (text user interface) that guides you through:

- Detecting the system and dependencies
- Choosing installation profile (Minimal, Standard, Complete)
- Selecting theme and Hyprland visual settings
- Installing system packages (optional, requires sudo)
- Writing configuration and creating desktop entries

## Step 3: Start AETHER

After installation, start the shell:

```bash
aether shell
```

Or add to your Hyprland config:

```ini
exec-once = aether shell
```

Open the applications:

```bash
aether settings   # Appearance, themes, wallpaper, bar, dashboard, notifications, etc.
aether music      # MPRIS player
aether monitor    # System resource monitor
aether files      # File browser
aether wallpaper  # Wallpaper picker and accent extraction
aether power      # Lock, suspend, logout, shutdown
aether launcher   # Standalone fuzzy launcher
```

## Troubleshooting

- If the installer fails due to missing packages, run `aether doctor` for diagnostics.
- For manual installation, see the [Manual Install](manual-install) page.
- If you need to repair an existing installation, run `aether-installer --repair` (or `make install` with `mode=repair`).

## Uninstalling

To remove AETHER completely, run:

```bash
./uninstall.sh
```

Or use the `aether uninstall` command if already installed.
