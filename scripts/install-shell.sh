#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: bash scripts/install-shell.sh [--force]"
  echo "Copies bashrc and tmux startup; --force backs up and replaces local changes."
}

FORCE=0
case "${1:-}" in
  "") ;;
  --force) FORCE=1 ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 1 ;;
esac
[[ $# -le 1 ]] || { usage >&2; exit 1; }

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
REPO="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="$STATE_ROOT/shell-dotfiles/installed"
BACKUP_DIR=""
SOURCES=("$REPO/bashrc" "$REPO/config/tmux/scripts/startup.sh")
TARGETS=(".bashrc" ".config/tmux/scripts/startup.sh")
MODES=(644 755)

conflicts=0
for i in "${!SOURCES[@]}"; do
  bash -n "${SOURCES[$i]}"
  dest="$HOME/${TARGETS[$i]}"
  previous="$STATE_DIR/${TARGETS[$i]}"
  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ ! -f "$dest" && ! -L "$dest" ]]; then
      echo "error: destination is not a file: $dest" >&2
      conflicts=1
    elif [[ -f "$dest" && ! -L "$dest" ]] && \
      { cmp -s "${SOURCES[$i]}" "$dest" || \
        { [[ -f "$previous" && ! -L "$previous" ]] && cmp -s "$previous" "$dest"; }; }; then
      continue
    elif [[ "$FORCE" == 0 ]]; then
      echo "conflict: $dest differs from dotfiles or the last installed copy; review it before using --force" >&2
      conflicts=1
    fi
  fi
done
[[ "$conflicts" == 0 ]] || exit 1

umask 077
for i in "${!SOURCES[@]}"; do
  src="${SOURCES[$i]}"
  dest="$HOME/${TARGETS[$i]}"
  previous="$STATE_DIR/${TARGETS[$i]}"
  if [[ -f "$dest" && ! -L "$dest" ]] && cmp -s "$src" "$dest"; then
    chmod "${MODES[$i]}" "$dest"
    echo "ok        $dest"
  else
    if [[ -e "$dest" || -L "$dest" ]]; then
      if [[ -z "$BACKUP_DIR" ]]; then
        mkdir -p "$STATE_ROOT/shell-dotfiles-backup"
        BACKUP_DIR="$(mktemp -d "$STATE_ROOT/shell-dotfiles-backup/$(date +%Y%m%d%H%M%S)-XXXXXX")"
      fi
      backup="$BACKUP_DIR/${TARGETS[$i]}"
      mkdir -p "$(dirname "$backup")"
      mv "$dest" "$backup"
      echo "backup    $backup"
    fi
    mkdir -p "$(dirname "$dest")"
    install -m "${MODES[$i]}" "$src" "$dest"
    echo "copied    $dest"
  fi
  mkdir -p "$(dirname "$previous")"
  install -m 600 "$src" "$previous"
done

echo
echo "Done. Open a new shell to load bashrc; existing tmux sessions are not restarted."
