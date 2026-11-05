---
title: Download
---

# Download

AETHER is distributed via its GitHub releases. Download the pre‑built installer binary or build from source.

## Release Binary

Download `aether-installer-<version>-x86_64-linux` from the [Releases](https://github.com/aether-desktop/AETHER/releases) page, verify with `SHA256SUMS` and run it:

```bash
sha256sum -c SHA256SUMS --ignore-missing
chmod +x aether-installer-<version>-x86_64-linux
./aether-installer-<version>-x86_64-linux
```

## Building from Source

```bash
git clone https://github.com/aether-desktop/AETHER.git
cd AETHER
make build-installer    # cargo build --release --manifest-path installer/Cargo.toml
make install-user       # copies to ~/.local, never requires root
```

Alternatively, use the bootstrap script:

```bash
cd AETHER
./install.sh
```
