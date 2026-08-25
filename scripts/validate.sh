#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

required=(
  README.md LICENSE THIRD_PARTY_NOTICES.md SECURITY.md
  install.sh uninstall.sh
  .config/hypr/hyprland.lua
  .config/omarchy/shell.json
  .config/quickshell/bar/shell.qml
)
for path in "${required[@]}"; do
  [[ -f $path ]] || { printf 'Missing required file: %s\n' "$path" >&2; exit 1; }
done

while IFS= read -r script; do
  bash -n "$script"
done < <(rg -l '^#!.*\b(bash|sh)\b' .config .local scripts install.sh uninstall.sh)

while IFS= read -r json; do
  jq empty "$json"
done < <(find .config -type f -name '*.json' -print | LC_ALL=C sort)

python - <<'PY'
import ast
from pathlib import Path

for path in sorted(Path('.').glob('**/*.py')):
    if '.git' not in path.parts:
        ast.parse(path.read_text(encoding='utf-8'), filename=str(path))
PY

private_pattern='(/home/chara|Troia|Foggia|eDP-1|AG15-71P|JBL TUNE510BT|F8:AB:E5|015312|gho_[A-Za-z0-9_]+|github_pat_[A-Za-z0-9_]+)'
if rg -n -I -g '!scripts/validate.sh' "$private_pattern" .; then
  printf 'Private or machine-specific content detected.\n' >&2
  exit 1
fi

if find .config/omarchy/themes/chara-determination -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
    -print -quit | grep -q .; then
  printf 'Redistributable theme must not contain third-party artwork.\n' >&2
  exit 1
fi

if find . -path './.git' -prune -o -type f \
    \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.woff' -o -iname '*.woff2' \) \
    -print -quit | grep -q .; then
  printf 'Restricted font binary detected.\n' >&2
  exit 1
fi

manifest_count="$(find .config/omarchy/plugins -name manifest.json -type f | wc -l)"
unique_ids="$(find .config/omarchy/plugins -name manifest.json -type f -print0 \
  | xargs -0 -r jq -r '.id' | LC_ALL=C sort -u | wc -l)"
[[ $manifest_count == "$unique_ids" ]] || {
  printf 'Duplicate or missing plugin manifest IDs.\n' >&2
  exit 1
}

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git diff --check
fi

printf 'Validation passed: %s plugin manifests, no private patterns or restricted theme assets.\n' "$manifest_count"
