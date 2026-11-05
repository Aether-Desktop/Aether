---
title: About
---

# About AETHER

AETHER (pronounced "ether") is an open‑source Linux desktop ecosystem that aims to provide a cohesive, Material You‑inspired experience across the entire user journey. The name reflects the goal of unifying shell, applications, configuration and documentation into a single, breathable atmosphere.

## Philosophy

- **Your desktop.** A complete, first‑class desktop environment for Arch Linux.
- **Your atmosphere.** Design that adapts to your wallpaper and preferences, with dynamic accent extraction.
- **Your AETHER.** A project built by and for the community, extensible for other distributions.

## Design Principles

- **Dark‑first.** Optimized for night usage and low‑light environments.
- **Rounded/translucent.** Modern aesthetics with subtle depth.
- **Material You.** Leveraging Android’s design language for familiarity and elegance.
- **Consistency.** Unified visual language across shell, apps, installer and website.

## Technical Stack

| Layer | Technology |
|-------|------------|
| Shell | Quickshell, QML, Qt Quick |
| Apps | Quickshell, shared QML modules, MPRIS |
| Installer | Rust, Ratatui, Crossterm, serde |
| Website | Astro, TypeScript, Tailwind CSS |
| Configuration | JSON schemas, atomic writes, backups |
| Hyprland | Static keybind file, generated visual settings |

## Community

- **GitHub:** https://github.com/aether-desktop/AETHER
- **Discussions:** GitHub Discussions tab
- **Issues:** Report bugs and request features

## Roadmap

- [x] Core shell and design system
- [x] Application suite (Settings, Music, Monitor, Files, Wallpaper, Power Menu)
- [x] Installer with TUI and safety guarantees
- [x] Website with documentation
- [x] CI/CD pipelines for website deploy and installer releases
- [ ] Packaging for distributions (packaging abstraction ready)
- [ ] Advanced widgets and customizations

## Support

AETHER is maintained by the AETHER Project. While we aim to provide a stable experience, note that the project is still in early development and may evolve.

If you encounter bugs, please file an issue with the output of `aether doctor`.

## License

AETHER is licensed under the MIT License. See `LICENSE` for details.
