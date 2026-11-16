#!/usr/bin/env bash
# Installs the portable T3 Code environment settings from this dotfiles checkout:
# - keybindings.json as a symlink into the environment's userdata directory
# - themes/*.json into the environment's themes directory
# - the default environment theme, so connected web/desktop clients switch to it
#
# Appearance preferences (fonts, sizes, window layout) are per device and are not
# handled here. See the T3 Code section in the repository README.
#
# Safe to rerun: correct links are kept, different files are backed up under
# ~/.local/state, and publishing the same theme again just refreshes clients.
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
T3CODE_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
T3_HOME="${T3CODE_HOME:-$HOME/.t3}"
STATE_DIR="$T3_HOME/userdata"
THEMES_DIR="$STATE_DIR/themes"
DEFAULT_THEME="${T3CODE_DEFAULT_THEME:-matte-black}"
BACKUP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/t3code-dotfiles-backup/$(date +%Y%m%d%H%M%S)"

backup_path() {
  local path="$1"
  local backup="$BACKUP_DIR${path#"$HOME"}"
  mkdir -p "$(dirname "$backup")"
  mv "$path" "$backup"
  echo "backup    $backup"
}

link() {
  local src="$1"
  local dest="$2"

  if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
    echo "ok        $dest"
    return
  fi

  mkdir -p "$(dirname "$dest")"

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ -f "$dest" && ! -L "$dest" ]] && cmp -s "$src" "$dest"; then
      rm "$dest"
    else
      backup_path "$dest"
    fi
  fi

  ln -s "$src" "$dest"
  echo "linked    $dest -> $src"
}

find_t3() {
  if command -v t3 >/dev/null 2>&1; then
    command -v t3
    return 0
  fi

  local candidate
  for candidate in "$T3_HOME"/runtime/versions/*/t3 "$T3_HOME"/wsl-runtime/*/t3; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

link "$T3CODE_DIR/keybindings.json" "$STATE_DIR/keybindings.json"

mkdir -p "$THEMES_DIR"
for theme in "$T3CODE_DIR"/themes/*.json; do
  [[ -f "$theme" ]] || continue
  dest="$THEMES_DIR/$(basename "$theme")"

  if [[ -f "$dest" ]] && cmp -s "$theme" "$dest"; then
    echo "ok        $dest"
    continue
  fi

  if [[ -e "$dest" ]]; then
    backup_path "$dest"
  fi

  cp "$theme" "$dest"
  echo "copied    $dest"
done

if [[ -f "$THEMES_DIR/$DEFAULT_THEME.json" ]]; then
  if T3_BIN="$(find_t3)"; then
    "$T3_BIN" theme set "$DEFAULT_THEME" --base-dir "$T3_HOME"
  else
    echo "warning: t3 not found; theme installed but not activated" >&2
  fi
else
  echo "warning: theme $DEFAULT_THEME not found in $THEMES_DIR" >&2
fi

echo
echo "Done. Restart T3 Code or reconnect clients to load the new keybindings."
echo "Connected web/desktop clients switch to the environment theme immediately."
