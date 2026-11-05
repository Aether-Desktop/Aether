# FAQ

## General Questions

### What is AETHER?

AETHER is a complete open‑source Linux desktop ecosystem built for Arch Linux and Hyprland. It includes a Quickshell shell, a suite of first‑party applications, a Rust‑based installer, an Astro website and comprehensive documentation.

### Is AETHER ready for daily use?

Yes. The initial release (v1.0.0) is considered stable for desktop use. It includes all core features: bar, launcher, dashboard, notifications, settings, media, system monitor, files, wallpaper and power menu.

### Can I use AETHER on other distributions?

AETHER is first‑class on Arch Linux only. The installer has abstraction points for Fedora, openSUSE and NixOS; see [docs/limitations.md](limitations.md) for details and known limitations.

### What are the system requirements?

- Arch Linux (≥ 2019.06)
- Hyprland Wayland (≥ 0.40)
- Quickshell (≥ 0.2) (source provided at `/tmp/opencode/qs-src`)
- PipeWire + WirePlumber (audio)
- NetworkManager (network)
- BlueZ (Bluetooth)
- A Nerd Font or Inter for typography

### How do I get support?

- Open an issue on GitHub and include the output of `aether doctor`.
- Check the documentation (`docs/`) for common problems.
- For development questions, see [docs/contributing.md](contributing.md).

## Installation Questions

### How do I install AETHER?

Run the built‑in installer:

```bash
git clone https://github.com/aether-desktop/AETHER.git
cd AETHER
./install.sh
```

Alternatively, build from source with `make build-installer` and run manually.

### Why does the installer ask for root?

The installer uses `sudo -n` only to install missing Arch packages (if you selected the Complete profile). If you already have those packages installed, sudo is not needed. The rest of the installation runs without root.

### Can I install AETHER without sudo?

Yes. The default profile (Standard) does not install system packages. Use `--dry-run` to preview what would be installed.

## Usage Questions

### How do I change the theme?

Open **AETHER Settings → Appearance → Theme**. Select a theme from the list. The theme is applied instantly.

### How do I customize the bar?

Open **AETHER Settings → Bar** to toggle widgets, adjust position, height, margin, exclusive mode, etc.

### How do I set wallpaper?

Open **AETHER Settings → Appearance → Wallpaper**. Choose from default wallpapers or pick a custom image. You can also set a wallpaper accent color.

### How do I add apps to the launcher?

Drag apps from the Applications menu, or use **AETHER Settings → Bar → Launcher Favorites**.

### How do I get system stats?

The **System Monitor** app (`aether monitor`) shows CPU, RAM, GPU, disk, network and temperature with a history chart.

### How do I control media?

Use the **Music** app (`aether music`) for MPRIS player control, volume and artwork.

### How do I manage notifications?

All notifications are shown in the **Notification Centre** (`aether notifications`). You can configure do‑not‑disturb, grouping, timeout and position in **AETHER Settings → Notifications**.

### How do I lock the screen?

Press **Super + Escape** (default Hyprland shortcut) or use the **Power Menu** (`aether power`) → Lock.

### How do I switch workspaces?

Use **Super + arrow keys** (default Hyprland bindings) or the workspace overview widget in the bar.

## Development Questions

### How do I add a new widget?

See **docs/widgets.md** for a step‑by‑step guide.

### How do I contribute a theme?

Submit a JSON file in `themes/` following the schema. The theme will be listed in `themes/index.json` (you can open a PR to add it).

### How do I build the website?

Run `make build-website` in the repository root. This runs `npm ci && npm run build --prefix website`.

### How do I run the installer tests?

Run `cargo test --manifest-path installer/Cargo.toml`.

### How do I check shell QML syntax?

Run `qmlformat -n shell/shell.qml` and verify with `qml6` (if available).

## Limitations

- **Unsupported distributions**: Fedora, openSUSE and NixOS are not officially supported; the installer includes abstraction points that may require manual configuration.
- **Sudo**: The installer uses `sudo -n`; you must have cached sudo credentials (`sudo -v` in another terminal first).
- **Quickshell**: The Quickshell binary is not included in this repository; you must install it separately (see README).
- **Network dependencies**: The installer requires network access for detection and package installation.
- **Display**: A working Wayland session with Hyprland is required. X11 fallback is not supported.

## Troubleshooting

### The installer fails with "No such file or directory"

Ensure you have the required toolchains installed (`~/.local/opt/node`, `~/.cargo/bin`). Export them to your PATH.

### The shell fails to start

Check that Quickshell is installed (`quickshell --version`). Verify that `AETHER_DATA_DIR` points to the correct checkout.

### Settings app crashes

Restart Hyprland after applying changes. If the crash persists, check for invalid QML syntax.

### The installer does not appear in PATH after installation

The installer links `~/.local/bin/aether`. Ensure `~/.local/bin` is in your `PATH`.

### How do I update AETHER?

Run the installer again. It will back up existing configuration, merge new defaults, and reinstall program files.
