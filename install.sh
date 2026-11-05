#!/usr/bin/env bash
# AETHER bootstrap for the TUI installer
# Finds the compiled installer, builds it from source if missing, and launches it.

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

# Locate or build the installer
if command -v aether-installer >/dev/null 2>&1; then
    installer="aether-installer"
elif [ -f "installer/target/release/aether-installer" ]; then
    installer="installer/target/release/aether-installer"
else
    echo "Building AETHER installer from source..."
    cargo build --release --manifest-path installer/Cargo.toml
    installer="installer/target/release/aether-installer"
fi

echo "Launching AETHER installer..."
exec "$installer" "$@"
