---
title: Installation
pubDate: 2024-01-01
---

# Installation

AETHER can be installed via the built-in TUI installer or manually.

## Quick Install (recommended)

```bash
git clone https://github.com/aether-desktop/AETHER.git
cd AETHER
./install.sh
```

## Manual / Development Install

```bash
git clone https://github.com/aether-desktop/AETHER.git
cd AETHER
make build-installer
make install-user
```

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
