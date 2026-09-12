# Public Chara rice agent instructions

## Portable configuration contracts

- Keep this public edition free of private locations, device addresses, user paths, package fingerprints, credentials, Steam assets, and non-redistributable artwork/fonts. Do not copy the private dotfiles snapshot wholesale.
- Preserve the documented Omarchy compatibility gate, user-file backups, reversible uninstall behavior, and the boundary excluding `/usr/share/omarchy`.
- Preserve the user's existing wallpaper unless live wallpaper was explicitly selected. Optional integrations and package installation must remain opt-in through their documented controls.
- Keep Rise variant compatibility and readable terminal fallbacks. Preserve the existing design's distinction between persistent palette accents and temporary semantic colors rather than changing the visual direction during maintenance.
- Preserve attribution and redistribution boundaries in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Gallery screenshots do not grant permission to bundle the depicted third-party assets.

## Guidance and verification

Use [README.md](README.md) for installation/user-facing behavior and [SECURITY.md](SECURITY.md) for security reporting. Test installer/uninstaller changes in isolated temporary home/state directories with controlled package/service commands. Check backups, overwrite scope, and restoration, not just shell syntax.

Installing packages, reloading Hyprland, restarting services, and changing live settings are separate system mutations, not automatic validation. Do not assume a new installation has the original maintainer's hardware or private assets.

Finish with affected portability, privacy, backup/recovery, and UI contracts checked, documentation synchronized, and actual native-session verification limits stated.
