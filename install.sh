#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
state_root="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-chara-rice"
install_packages=false
enable_live_wallpaper=false
confirmed=false

usage() {
  printf '%s\n' \
    'Usage: ./install.sh --yes [--install-packages] [--enable-live-wallpaper]' \
    '' \
    'Installs the public Chara rice after creating a reversible user backup.' \
    'It never writes to /usr/share/omarchy and does not replace your wallpaper.'
}

for arg in "$@"; do
  case "$arg" in
    --yes) confirmed=true ;;
    --install-packages) install_packages=true ;;
    --enable-live-wallpaper) enable_live_wallpaper=true ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$arg" >&2; usage >&2; exit 2 ;;
  esac
done

[[ $confirmed == true ]] || { usage >&2; exit 2; }
(( EUID != 0 )) || { printf 'Run this installer as your normal user, not root.\n' >&2; exit 1; }
command -v omarchy >/dev/null 2>&1 || { printf 'Omarchy is required.\n' >&2; exit 1; }
command -v rsync >/dev/null 2>&1 || { printf 'rsync is required. Install it with: omarchy pkg add rsync\n' >&2; exit 1; }

version="$(omarchy version 2>/dev/null || true)"
[[ $version == *'4.'* ]] || {
  printf 'This release is tested only with Omarchy 4; detected: %s\n' "${version:-unknown}" >&2
  exit 1
}

if [[ -f $state_root/installed-backup ]]; then
  printf 'The rice is already installed. Run ./uninstall.sh --yes before reinstalling.\n' >&2
  exit 1
fi

if [[ $install_packages == true ]]; then
  mapfile -t packages < <(sed -E '/^[[:space:]]*(#|$)/d' "$repo_dir/packages/required.txt")
  ((${#packages[@]} > 0)) && omarchy pkg add "${packages[@]}"
fi

stamp="$(date '+%Y%m%dT%H%M%S%z')"
mkdir -p "$state_root/backups"
backup_dir="$(mktemp -d "$state_root/backups/$stamp.XXXXXX")"
mkdir -p "$backup_dir/overwritten/.config" "$backup_dir/overwritten/.local" "$backup_dir/state"

quicklook_service_rel=".local/share/dbus-1/services/org.gnome.NautilusPreviewer.service"
quicklook_extension_rel=".local/share/nautilus-python/extensions/quick_look.py"
for rel in "$quicklook_service_rel" "$quicklook_extension_rel"; do
  target="$HOME/$rel"
  if [[ -f $target || -L $target ]]; then
    mkdir -p "$backup_dir/overwritten/$(dirname "$rel")"
    cp -a "$target" "$backup_dir/overwritten/$rel"
  fi
done

theme_name_file="$HOME/.local/state/omarchy/current/theme.name"
background_link="$HOME/.local/state/omarchy/current/background"
[[ -f $theme_name_file ]] && cp -a "$theme_name_file" "$backup_dir/state/theme.name"
[[ -L $background_link ]] && readlink "$background_link" > "$backup_dir/state/background.path"
[[ -d $HOME/.local/state/quickshell-rise ]] && cp -a "$HOME/.local/state/quickshell-rise" "$backup_dir/state/"
systemctl --user is-enabled chara-live-wallpaper.service >/dev/null 2>&1 \
  && : > "$backup_dir/state/live-wallpaper.was-enabled" || true
systemctl --user is-active chara-live-wallpaper.service >/dev/null 2>&1 \
  && : > "$backup_dir/state/live-wallpaper.was-active" || true

(
  cd "$repo_dir"
  {
    find .config .local -type f -print
    printf '%s\n' "$quicklook_service_rel" "$quicklook_extension_rel"
  } | LC_ALL=C sort -u
) > "$backup_dir/installed-files"

rsync -a --backup --backup-dir="$backup_dir/overwritten/.config" \
  "$repo_dir/.config/" "$HOME/.config/"
rsync -a --backup --backup-dir="$backup_dir/overwritten/.local" \
  "$repo_dir/.local/" "$HOME/.local/"

mkdir -p "$HOME/.local/share/dbus-1/services" "$HOME/.local/share/nautilus-python/extensions"
printf '%s\n' \
  '[D-BUS Service]' \
  'Name=org.gnome.NautilusPreviewer' \
  "Exec=$HOME/.config/omarchy/plugins/andreconde.quick-look/bin/quick-look-previewer" \
  > "$HOME/$quicklook_service_rel"
install -m 0644 \
  "$repo_dir/.config/omarchy/plugins/andreconde.quick-look/nautilus/quick_look.py" \
  "$HOME/$quicklook_extension_rel"

printf '%s\n' "$backup_dir" > "$state_root/installed-backup"

mkdir -p "$HOME/.local/state/quickshell-rise"
printf 'v2\n' > "$HOME/.local/state/quickshell-rise/active-variant"

systemctl --user daemon-reload
if [[ $enable_live_wallpaper == true ]]; then
  if command -v linux-wallpaperengine >/dev/null 2>&1; then
    systemctl --user enable --now chara-live-wallpaper.service
  else
    printf 'linux-wallpaperengine is absent; the optional service was not enabled.\n' >&2
  fi
fi

OMARCHY_THEME_SKIP_BACKGROUND=1 omarchy theme set 'Chara Determination'
hyprctl reload >/dev/null
if [[ -n $(hyprctl configerrors) ]]; then
  printf 'Hyprland reported configuration errors after installation.\n' >&2
  hyprctl configerrors >&2
  exit 1
fi
omarchy restart shell
command -v nautilus >/dev/null 2>&1 && nautilus -q >/dev/null 2>&1 || true

printf 'Installed successfully. Backup: %s\n' "$backup_dir"
