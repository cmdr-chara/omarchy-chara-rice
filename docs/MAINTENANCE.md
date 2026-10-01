# Maintenance and recovery

## Before updating Omarchy

Commit local changes or copy them elsewhere. Omarchy package files under
`/usr/share/omarchy` are never modified by this project; all overrides live in
the user configuration tree.

After an Omarchy update:

```bash
hyprctl reload
hyprctl configerrors
omarchy restart shell
systemctl --user --failed
```

Check Rise and shell logs if the panel does not reload:

```bash
journalctl --user -b --no-pager | rg -i 'quickshell|omarchy-shell|qml|error'
```

## Audio stability

RTKit is intentionally not installed by this project. It caused a repeatable
WirePlumber `SIGKILL` restart loop on the reference laptop workload. The stable
configuration uses PipeWire's native scheduling fallback. If Bluetooth is
connected but absent from audio outputs, inspect WirePlumber before changing
the sink:

```bash
systemctl --user status wireplumber
wpctl status
```

## Live wallpaper

The optional service is disabled by default. Inspect it with:

```bash
systemctl --user status chara-live-wallpaper.service
journalctl --user -u chara-live-wallpaper.service -b --no-pager
```

Disable it without touching the rest of the rice:

```bash
systemctl --user disable --now chara-live-wallpaper.service
```

The performance drop-in gives the renderer lower CPU and I/O scheduling
priority while keeping its 30 FPS limit. The service remains optional, and
original Steam assets are never installed by this repository.

## Themes and panels

Chara Determination is the current palette. Keep the browser's explicit dark
`chromium.theme` seed when adjusting the Chara colors. OpenCode theme files
are installed separately from CLI preferences so an update does not replace
keybindings or other settings.

Check the Apps catalog, launch a known application, and inspect the principal
Rise V2 panels after changing the shell. `chara-rice panel <name>` opens a
panel for inspection; `chara-rice close-panel` dismisses it. The lock preview
commands exercise presentation without locking the session.

## Optional Argus integration

Argus is an external, opt-in system monitor. It is not copied by the portable
installer, so updating the rice does not change its code or history. Inspect
the upstream release before updating the live plugin:

```bash
omarchy plugin update io.github.diegopluna.argus
omarchy plugin validate ~/.config/omarchy/plugins/io.github.diegopluna.argus
```

Argus keeps its flight-recorder data under
`~/.local/state/argus/`. Its alert hook is empty by default; review any
configured `alertCommand` before enabling it because that command can send
system information outside the machine. Remove the integration with:

```bash
omarchy plugin remove io.github.diegopluna.argus --yes
```

## Full rollback

Run `./uninstall.sh --yes` from the same clone used for installation. The active
backup pointer is stored at
`~/.local/state/omarchy-chara-rice/installed-backup`. Backups are retained after
uninstall so recovery remains possible.
