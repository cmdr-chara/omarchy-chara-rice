#!/usr/bin/env bash
set -Eeuo pipefail

state_root="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-chara-rice"
confirmed=false

usage() {
  printf '%s\n' \
    'Usage: ./uninstall.sh --yes' \
    '' \
    'Removes installed rice files and restores the pre-install user backup.'
}

for arg in "$@"; do
  case "$arg" in
    --yes) confirmed=true ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$arg" >&2; usage >&2; exit 2 ;;
  esac
done

[[ $confirmed == true ]] || { usage >&2; exit 2; }
(( EUID != 0 )) || { printf 'Run this uninstaller as your normal user, not root.\n' >&2; exit 1; }
command -v rsync >/dev/null 2>&1 || { printf 'rsync is required.\n' >&2; exit 1; }

marker="$state_root/installed-backup"
[[ -f $marker ]] || { printf 'No active installation record was found.\n' >&2; exit 1; }
backup_dir="$(<"$marker")"
case "$backup_dir" in
  "$state_root"/backups/*) ;;
  *) printf 'Refusing unsafe backup path: %s\n' "$backup_dir" >&2; exit 1 ;;
esac
[[ -f $backup_dir/installed-files && -d $backup_dir/overwritten ]] || {
  printf 'The installation backup is incomplete: %s\n' "$backup_dir" >&2
  exit 1
}

stamp="$(date '+%Y%m%dT%H%M%S%z')"
mkdir -p "$state_root/pre-uninstall"
safety_dir="$(mktemp -d "$state_root/pre-uninstall/$stamp.XXXXXX")"

while IFS= read -r rel; do
  [[ $rel == .config/* || $rel == .local/* ]] || {
    printf 'Refusing unsafe manifest entry: %s\n' "$rel" >&2
    exit 1
  }
  target="$HOME/$rel"
  if [[ -f $target || -L $target ]]; then
    mkdir -p "$safety_dir/$(dirname "$rel")"
    cp -a "$target" "$safety_dir/$rel"
    unlink "$target"
  fi
done < "$backup_dir/installed-files"

systemctl --user disable --now chara-live-wallpaper.service 2>/dev/null || true
rsync -a "$backup_dir/overwritten/" "$HOME/"

if [[ -f $backup_dir/state/theme.name ]]; then
  previous_theme="$(<"$backup_dir/state/theme.name")"
  [[ -n $previous_theme ]] && omarchy theme set "$previous_theme"
fi
if [[ -f $backup_dir/state/background.path ]]; then
  previous_background="$(<"$backup_dir/state/background.path")"
  [[ -f $previous_background ]] && omarchy theme bg set "$previous_background"
fi
if [[ -d $backup_dir/state/quickshell-rise ]]; then
  if [[ -d $HOME/.local/state/quickshell-rise ]]; then
    mv "$HOME/.local/state/quickshell-rise" "$safety_dir/quickshell-rise-state"
  fi
  cp -a "$backup_dir/state/quickshell-rise" "$HOME/.local/state/"
fi

systemctl --user daemon-reload
if [[ -f $backup_dir/state/live-wallpaper.was-enabled ]]; then
  systemctl --user enable chara-live-wallpaper.service
fi
if [[ -f $backup_dir/state/live-wallpaper.was-active ]]; then
  systemctl --user start chara-live-wallpaper.service
fi
hyprctl reload >/dev/null 2>&1 || true
omarchy restart shell
command -v nautilus >/dev/null 2>&1 && nautilus -q >/dev/null 2>&1 || true
unlink "$marker"

printf 'Uninstalled successfully. Pre-uninstall safety copy: %s\n' "$safety_dir"
