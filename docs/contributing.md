# Contributing

Thank you for considering contributing to AETHER! This guide covers how to report issues, submit patches and improve the project.

## Reporting Issues

1. Ensure the issue hasn’t already been reported.
2. Use the GitHub issue templates (if present) and include:
   - System information (`aether doctor` output)
  (privately sensitive data)
3. Attach screenshots when helpful.

## Submission Guidelines

### Code Contributions

- Fork the repository and create a feature branch.
- Follow the existing code style (qmlformat for QML, Rust formatting for Rust, etc.).
- Run the checks via `make check` to ensure shell syntax, Rust tests and website typecheck pass.
- Make sure there are no shellcheck warnings for any script.
- Do not introduce unsafe shell interpolation or `curl | sh` patterns.
- Ensure any new files or directories are added with appropriate permissions (scripts executable, configs readable).
- Add yourself to the contributor list in README.md (optional).
- Commit with a descriptive message and add Co-authored-by: openhands <openhands@all-hands.dev> if required.
- Push and open a pull request against `main`. Provide a clear description and reference any related issues.

### Documentation Contributions

- Update markdown files in `website/src/pages/` and `docs/`.
- Follow the existing structure and language.
- Ensure links are base‑path safe for GitHub Pages.
- Proofread for clarity and grammar.

## Development Setup

### Requirements

- **Arch Linux** (≥ 2019.06) – only officially supported today
- **Node v22.14.0** at `~/.local/opt/node` – for the website
- **Rust/Cargo 1.99.1** at `~/.cargo` – for the installer
- **Hyprland** Wayland compositor (≥ 0.40)
- **Quickshell** (≥ 0.2) source at `/tmp/opencode/qs-src` used as API reference (binary absent in this repo)

### Building

```bash
cd /home/daniel/AETHER
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

### Testing

All unit and integration tests are run via `cargo test`. The website typecheck is performed via `npm run typecheck`.

### Code Quality

- **Shell scripts**: use `bash -n` to validate syntax, avoid quoting issues.
- **Rust**: run `cargo clippy` (not configured here) and `cargo test`.
- **QML**: run `qmlformat -n` on all `.qml` files and verify no parse errors.
- **Website**: run `npm run typecheck` and `npm run build`.

## Code of Conduct

Please behave professionally and respect all contributors. Abuse will be addressed.

## License

AETHER is licensed under the MIT License. See `LICENSE` for details.

## Acknowledgments

Special thanks to the open‑source communities for Quickshell, Hyprland, Rust, Astro and all other dependencies.

## Contributor Covenant

We follow the Contributor Covenant [Code of Conduct](CODE_OF_CONDUCT.md). Please read it and respect the guidelines when interacting with the project.
