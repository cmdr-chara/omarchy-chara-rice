#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

export HOME="$test_root/home"
export XDG_STATE_HOME="$HOME/.local/state"
export TEST_COMMAND_LOG="$test_root/commands.log"
export PATH="$repo_dir/tests/fake-bin:$PATH"

mkdir -p "$HOME/.config/hypr" "$HOME/.local/state/omarchy/current" "$HOME/.local/share/dbus-1/services"
printf 'original binding\n' > "$HOME/.config/hypr/bindings.lua"
printf 'original preview service\n' > "$HOME/.local/share/dbus-1/services/org.gnome.NautilusPreviewer.service"
printf 'Tokyo Night\n' > "$HOME/.local/state/omarchy/current/theme.name"
: > "$TEST_COMMAND_LOG"

"$repo_dir/install.sh" --yes

[[ -f $XDG_STATE_HOME/omarchy-chara-rice/installed-backup ]]
rg -q 'Chara Soul OSD' "$HOME/.config/omarchy/plugins/chara.osd/manifest.json"
[[ -f $HOME/.config/omarchy/themes/chara-determination/colors.toml ]]
[[ -f $HOME/.config/opencode/themes/lucent-chara.json ]]
[[ -x $HOME/.local/bin/chara-fastfetch ]]
rg -q 'quick-look-previewer' "$HOME/.local/share/dbus-1/services/org.gnome.NautilusPreviewer.service"
[[ -f $HOME/.local/share/nautilus-python/extensions/quick_look.py ]]
[[ $(<"$HOME/.local/state/quickshell-rise/active-variant") == v2 ]]
if rg -q 'enable --now chara-live-wallpaper' "$TEST_COMMAND_LOG"; then
  printf 'Default installation unexpectedly enabled the live wallpaper.\n' >&2
  exit 1
fi

printf 'changed after install\n' > "$HOME/.config/hypr/bindings.lua"
"$repo_dir/uninstall.sh" --yes

[[ $(<"$HOME/.config/hypr/bindings.lua") == 'original binding' ]]
[[ $(<"$HOME/.local/share/dbus-1/services/org.gnome.NautilusPreviewer.service") == 'original preview service' ]]
[[ ! -e $HOME/.local/share/nautilus-python/extensions/quick_look.py ]]
[[ ! -e $HOME/.local/bin/chara-live-wallpaper ]]
[[ ! -e $XDG_STATE_HOME/omarchy-chara-rice/installed-backup ]]
find "$XDG_STATE_HOME/omarchy-chara-rice/pre-uninstall" -type f -name bindings.lua -print -quit | grep -q .

# The opt-in path enables the service and resolves an automatic monitor without
# embedding a machine-specific output name.
mkdir -p "$HOME/.local/share/Steam/steamapps/common/wallpaper_engine/assets"
"$repo_dir/install.sh" --yes --enable-live-wallpaper
rg -q 'systemctl --user enable --now chara-live-wallpaper.service' "$TEST_COMMAND_LOG"
"$HOME/.local/bin/chara-live-wallpaper"
rg -q -- '--screen-root TEST-1' "$TEST_COMMAND_LOG"
rg -q -- '--fps 30 3450338231' "$TEST_COMMAND_LOG"
"$repo_dir/uninstall.sh" --yes

printf 'Install/uninstall integration test passed.\n'
