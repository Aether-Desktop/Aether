# Installation

This document describes how to install AETHER on Arch Linux.

## Quick Install

```bash
git clone https://github.com/aether-desktop/AETHER.git
cd AETHER
./install.sh
```

The installer is a TUI (text user interface) that guides you through the installation process.

## Manual / Development Install

```bash
git clone https://github.com/aether-desktop/AETHER.git
cd AETHER
make build-installer
make install-user
```

### make install-user

The `install-user` target copies AETHER to `~/.local` (prefix) and creates the `aether` command in `~/.local/bin`. It never requires root privileges.

Start Hyprland, then:

```bash
aether shell
aether settings
aether launcher
```

Or add to your Hyprland config:

```ini
exec-once = aether shell
```

## Troubleshooting

- If the installer fails due to missing system packages, you may need to authenticate `sudo` (the installer uses `sudo -n`).
- For a full list of dependencies, see the installer’s detection output (`aether-installer --help`).

## Verified vs. Unverified

AETHER is verified on Arch Linux only. The installer includes abstraction points for Fedora, openSUSE and NixOS; see [docs/limitations.md](limitations.md) for details.
