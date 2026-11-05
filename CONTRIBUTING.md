# Contributing to AETHER

Thanks for helping build a desktop that feels like home. This guide covers the
practical details; the deeper design contract is in
[docs/design-system.md](docs/design-system.md).

## Ground rules

- Be kind. Read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
- Do not claim something works if you have not run it. Label unverified work.
- Do not execute downloaded scripts or add `curl | sh` installation paths.
- Do not overwrite user configuration. Back it up with a timestamp.
- Keep components independently buildable (`shell`, `apps`, `installer`, `website`).
- No fabricated screenshots, analytics, or placeholder data presented as real.

## Development setup

### Shell (QML)

```bash
# Arch dependencies (example)
sudo pacman -S quickshell qt6-declarative qt6-svg pipewire wireplumber \
  networkmanager bluez bluez-utils upower

# Run directly from the repository
qs -p shell/shell.qml
```

QML style:

- 2-space indentation, one property per line once an object grows.
- Shared visual primitives live in `shell/Aether/`; do not re-implement surfaces,
  switches, sliders or icon buttons in app directories.
- Use semantic theme roles (`Theme.surface`, `Theme.primary`, `Theme.onSurface`) —
  never hard-coded colors, except inside theme definitions.
- Use Quickshell service APIs rather than spawning shell pipelines where an API exists.
  When a CLI is required, pass argument arrays (`Process.command`), never interpolated
  shell strings.

### Installer (Rust)

```bash
cd installer
cargo fmt
cargo clippy -- -D warnings
cargo test
cargo run -- --dry-run
```

Rules:

- All process execution goes through `system::command::CommandSpec` (argument arrays,
  no shell), and every mutating action is logged.
- Every file write goes through `backup::write_with_backup`.
- Uninstall only removes paths recorded in the AETHER manifest.
- New behavior needs a test. Filesystem tests use temporary directories.

### Website (Astro)

```bash
cd website
npm ci
npm run dev
npm run check   # astro check (TypeScript + templates)
npm run build
```

Use semantic components (`Card`, `Button`, `Section`) and verify keyboard navigation
and the mobile layout. Never hard-code absolute asset paths; use `withBase()`.

## Commit messages

Conventional Commits are appreciated:

```
feat(shell): add per-monitor bar visibility
fix(installer): never follow symlinks in uninstall
docs: correct Quickshell version requirement
```

## Pull requests

1. Fork, branch from `main`.
2. Keep the change focused; include a short description of manual testing.
3. Run `make check` (or the component-specific checks).
4. Add screenshots for visual changes — real captures only, or clearly marked
   design previews.
5. Update docs and `CHANGELOG.md` under `Unreleased`.

CI must pass. A maintainer will review for design-system consistency and safety.

## Adding a theme

Themes are JSON documents. Copy `themes/aether-dark.json`, adjust the semantic roles,
add it to `themes/index.json`, and run `./scripts/validate-themes.sh`. See
[docs/themes.md](docs/themes.md).

## Adding a widget

Widgets are declarative QML plus an optional data-only manifest. Follow
[docs/widget-development.md](docs/widget-development.md). Third-party manifests never
declare commands to execute; AETHER does not auto-run downloaded code.

## Release process

Maintainers tag `vX.Y.Z`; `.github/workflows/release.yml` builds the installer for
x86_64 and aarch64, runs tests, generates `SHA256SUMS`, and publishes the release only
if every required job succeeds.
