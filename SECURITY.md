# Security policy

AETHER runs with your user privileges and controls desktop components, so we take
security reports seriously.

## Reporting

Email `security@aether-desktop.dev` (PGP available on request). Do not open a public
issue for an exploitable problem. We aim to acknowledge within 72 hours and to ship a
fix or mitigation as soon as practical. We will credit you unless you prefer otherwise.

## Scope

- AETHER installer (privilege use, command execution, path handling, backups)
- Shell/app QML (command injection, unsafe file handling, plugin loading)
- Website build/deploy (supply chain, generated content)
- GitHub workflows (secret exposure, untrusted PR handling)

## Design commitments

1. **No shell interpolation.** Processes are executed with argument arrays. The
   installer never invokes `sh -c`.
2. **No remote script execution.** `install.sh` never pipes a download into a shell.
3. **Explicit privilege.** The installer asks before any `sudo` operation and never
   assumes passwordless sudo.
4. **Untrusted plugins are data.** Widget/theme imports may provide JSON and images.
   They cannot declare commands and are never automatically executed. Theme imports
   reject unknown fields and invalid colors.
5. **Reversible installation.** Every modified file is backed up with a timestamp;
   uninstall only removes files listed in the AETHER manifest.
6. **Dry-run everywhere.** `--dry-run` performs detection and prints planned actions
   without writing.
7. **Pinned CI actions.** Release workflows use pinned action majors and fail closed.
