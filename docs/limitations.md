# Limitations

This document outlines known limitations and unsupported scenarios for AETHER.

## Distributions

AETHER is **first‑class only on Arch Linux**. The installer includes abstraction points for **Fedora**, **openSUSE** and **NixOS**, but these are not officially supported.

### What is unsupported?

- **Package detection**: The installer uses `pacman`. For other package managers, the `packages` component cannot be installed.
- **Configuration merging**: Some system paths differ across distributions (e.g., `/etc/hyprland.conf` vs `hyprland.conf`).
- **Desktop entry integration**: The `aether` command and app menu entries are installed only for Arch‑compatible XDG directories.

### How to use on other distributions?

1. Install the required system dependencies manually (Hyprland, Quickshell, PipeWire, etc.).
2. Patch the installer scripts to use the correct package manager (`dnf`, `zypper`, `nix-env`).
3. Adjust the `hyprland.conf` include path as needed.

For details, refer to the installer’s `src/distro.rs` and `src/hyprland.rs`.

## Runtime Dependencies

- **Quickshell**: Must be installed separately (not included in this repo). The installer checks for `quickshell` or `qs` binary.
- **Hyprland**: Requires a running Wayland compositor. The installer detects the presence of `HYPRLAND_INSTANCE_SIGNATURE`.
- **PipeWire**, **NetworkManager**, **BlueZ**: Required for audio, network and Bluetooth features. If missing, those UI components will show errors.
- **brightnessctl** and **hyprsunset**: Required for brightness and night‑light controls. Fallback handling is implemented.

## Installer Safety

The installer never pipes remote content into a shell and never passes user input through a shell. All file writes are atomic (temporary file + rename). Configuration backups are timestamped and stored in `~/.config/aether/backups`.

## Known Issues

- **Hyprland config generation**: The generated include is only applied when `hyprland.manageConfig` is true and `hyprctl reload` is run or Hyprland restarted.
- **Widget positioning**: Widgets may overflow the bar if `bar.height` is too small.
- **Theme accent extraction**: Requires a valid image; otherwise falls back to the theme's primary color.
- **Installer dry‑run**: Dry‑run does not test actual system packages (requires sudo). It only validates paths and merges configuration.

## Future Plans

- Add support for **Bacon** (Nix) and ** dnf** (Fedora) package managers.
- Integrate **Hyprland’s `hyprsunset`** for night‑light temperature adjustments via Settings.
- Add **widget marketplace** for third‑party contributions.
- Implement **per‑monitor scaling** and **DPIs**.
- Add **accessibility** options (high contrast, larger text).

## Support

If you encounter an issue that is not listed here, please open a GitHub issue and include the output of `aether doctor`. This will help us improve cross‑distribution compatibility.
