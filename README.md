# Chara Determination for Omarchy

A dark burgundy Omarchy 4 desktop built around Rise V1, Undertale battle-box
geometry, restrained Glitchtale energy, and semantic soul colors. The persistent
accent is muted garnet `#A45D68`; bright soul colors are reserved for temporary
states, notifications, and OSD feedback.

This is the public, portable edition of a real daily-driver configuration. It
contains no passwords, tokens, personal location, device address, package
fingerprint, Steam asset, or third-party fan artwork.

## What is included

- Hyprland layout, animations, bindings, idle integration, and window behavior.
- Rise V1 as the default bar, with the compatible V2 variant retained.
- Chara bar, lock screen, notifications, OSD, media, network, power, and
  workspace plugins.
- Mirador workspace overview and Quick Look file preview.
- Chara Determination theme palettes for the Omarchy shell.
- Matching Alacritty, Foot, Ghostty, Kitty, btop, and Starship configuration.
- Safe Bluetooth helper and optional self-healing live-wallpaper service.
- Reversible installer and uninstaller with user-state backups.

## Compatibility

- Tested on Omarchy `4.0.0-1`.
- Tested with Hyprland `0.56` and Quickshell `0.3.1`.
- The installer intentionally refuses non-Omarchy-4 systems.
- Nothing writes to `/usr/share/omarchy`.

## Install

Inspect the repository and package lists first, then run:

```bash
git clone https://github.com/cmdr-chara/omarchy-chara-rice.git
cd omarchy-chara-rice
./install.sh --yes --install-packages
```

The installer backs up every overwritten user file under
`~/.local/state/omarchy-chara-rice/backups/`, installs Rise V1, applies the
Chara palette, reloads Hyprland, and restarts the Omarchy shell. It does not
replace the current wallpaper.

Quick Look's D-Bus Space-key bridge and optional Nautilus context-menu file are
registered by the installer and restored or removed by the uninstaller.

Omit `--install-packages` if the packages in `packages/required.txt` are already
present. Optional preview integrations are listed in `packages/optional.txt`.

## Personal settings

### Weather

The public configuration contains no fixed location. Without configuration,
wttr.in may infer an approximate location from the network address. To choose a
location explicitly:

```bash
mkdir -p ~/.config/environment.d
cp examples/environment.conf.example ~/.config/environment.d/90-chara-rice.conf
```

Edit `CHARA_WEATHER_LOCATION`, then sign out and back in.

### Determination font

The font is not redistributed. Download the unchanged Determination Mono file
from the source documented in `THIRD_PARTY_NOTICES.md`, place it at:

```text
~/.local/share/fonts/Determination/DeterminationMonoWeb.ttf
```

Then run `fc-cache -f`. If the font is absent, the CHARA wordmark falls back to
the normal monospace UI font.

### Live wallpaper

The static wallpaper currently selected by the user is preserved. If
`linux-wallpaperengine` and Wallpaper Engine assets are already installed, the
optional referenced scene can be enabled with:

```bash
./install.sh --yes --install-packages --enable-live-wallpaper
```

Edit `~/.config/chara-rice/live-wallpaper.env` to select a different Workshop
item, monitor, asset directory, or FPS. The monitor defaults to automatic
detection. No Workshop content is stored in this repository.

## Key shortcuts

| Shortcut | Action |
|---|---|
| `Super + E` | Files |
| `Ctrl + Alt + T` | Terminal |
| `Super + Shift + S` | Region screenshot |
| `Super + Shift + O` | Mirador workspace overview |
| `Space` on a selected Nautilus file | Quick Look |
| Media and brightness keys | Chara OSD controls |

## Uninstall and rollback

From the cloned repository:

```bash
./uninstall.sh --yes
```

The uninstaller first creates a safety copy of the currently installed files,
removes only paths listed by the installer, restores overwritten files and the
previous theme/Rise state, then restarts the shell. Packages are never removed
automatically.

## Validation

```bash
./scripts/validate.sh
```

The same checks run on every GitHub push and pull request.

## Credits and license

Original repository work is MIT licensed. Rise, Omarchy-derived components,
Mirador, Quick Look, optional fonts, and artwork references are documented in
`THIRD_PARTY_NOTICES.md`. Undertale and Glitchtale imagery is not redistributed.

This is an unofficial fan project and is not affiliated with Toby Fox, Camila
Cuevas, Basecamp, or HANCORE Linux.
