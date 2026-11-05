#!/usr/bin/env bash
# AETHER manual uninstaller
set -euo pipefail

if command -v aether >/dev/null 2>&1; then
    exec aether uninstall "$@"
else
    echo "AETHER is not installed in PATH."
    exit 1
fi
