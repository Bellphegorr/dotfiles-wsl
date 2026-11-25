#!/usr/bin/env bash
# Installs the portable T3 Code environment settings from this dotfiles checkout:
# - keybindings.json as a symlink into the environment's userdata directory
# - themes/*.json into the environment's themes directory
# - the default environment theme, so connected web/desktop clients switch to it
#
# Appearance preferences (fonts, sizes, window layout) are per device and are not
# handled here. See the T3 Code section in the repository README.
#
# Safe to rerun: correct files are kept, local edits abort the run and --force
# backs them up before replacing. --verify is read-only and skips the theme
# activation call.
set -euo pipefail

usage() {
  echo "Usage: bash config/t3code/scripts/install.sh [--force|--verify]"
  echo "Links keybindings and copies themes; --force backs up and replaces local edits."
  echo "--verify only reports drift and exits 1 when anything is out of sync."
}

FORCE=0
VERIFY=0
while (($#)); do
  case "$1" in
    --force) FORCE=1 ;;
    --verify) VERIFY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
  shift
done
((FORCE && VERIFY)) && { usage >&2; exit 1; }

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
T3CODE_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
REPO="$(cd "$T3CODE_DIR/../.." && pwd)"
T3_HOME="${T3CODE_HOME:-$HOME/.t3}"
STATE_DIR="$T3_HOME/userdata"
THEMES_DIR="$STATE_DIR/themes"
DEFAULT_THEME="${T3CODE_DEFAULT_THEME:-matte-black}"
# shellcheck source=../../../scripts/install-lib.sh
source "$REPO/scripts/install-lib.sh"

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

install_begin t3code "$FORCE" "$VERIFY"

install_link_path "$T3CODE_DIR/keybindings.json" "$STATE_DIR/keybindings.json"

for theme in "$T3CODE_DIR"/themes/*.json; do
  [[ -f "$theme" ]] || continue
  install_file_path "$theme" "$THEMES_DIR/$(basename "$theme")" 644
done

install_run

if [[ "$VERIFY" == 0 ]]; then
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
fi
