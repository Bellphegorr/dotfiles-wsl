#!/usr/bin/env bash
# Shared copy/conflict engine for the dotfiles installers.
#
# Usage in a per-tool installer:
#   install_begin <tool> <force 0|1>
#   install_file <src> <target relative to $HOME> <mode>
#   install_link <src> <target relative to $HOME>
#   install_run
#
# install_run checks every destination first. Unchanged files are "ok";
# files replaced by a previous install are updated with a backup; anything
# else is a conflict that aborts the whole run unless --force is given. The
# last installed copy of each file is kept under
# $XDG_STATE_HOME/<tool>-dotfiles/installed to tell managed files from
# local edits.

declare -a INSTALL_SRC=() INSTALL_DST=() INSTALL_MODE=() INSTALL_KIND=()
INSTALL_TOOL=""
INSTALL_FORCE=0
INSTALL_STATE_ROOT=""
INSTALL_STATE_DIR=""
INSTALL_BACKUP_DIR=""

install_begin() {
  INSTALL_TOOL="$1"
  INSTALL_FORCE="${2:-0}"
  INSTALL_STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}"
  INSTALL_STATE_DIR="$INSTALL_STATE_ROOT/$INSTALL_TOOL-dotfiles/installed"
  INSTALL_BACKUP_DIR=""
}

install_file() {
  INSTALL_SRC+=("$1")
  INSTALL_DST+=("$2")
  INSTALL_MODE+=("$3")
  INSTALL_KIND+=("file")
}

install_link() {
  INSTALL_SRC+=("$1")
  INSTALL_DST+=("$2")
  INSTALL_MODE+=("")
  INSTALL_KIND+=("link")
}

# Already up to date: same content (files) or same target (links).
_install_current() { # kind src dest
  case "$1" in
    file) [[ -f "$3" && ! -L "$3" ]] && cmp -s "$2" "$3" ;;
    link) [[ -L "$3" && "$(readlink -f "$3")" == "$(readlink -f "$2")" ]] ;;
  esac
}

# Safe to replace without --force: current, or the last installed copy.
_install_managed() { # kind src dest previous
  if _install_current "$1" "$2" "$3"; then
    return 0
  fi
  [[ "$1" == file && -f "$3" && ! -L "$3" && -f "$4" && ! -L "$4" ]] && cmp -s "$4" "$3"
}

_install_backup() { # dest relative-target
  local dest="$1" rel="$2" backup
  if [[ -z "$INSTALL_BACKUP_DIR" ]]; then
    mkdir -p "$INSTALL_STATE_ROOT/$INSTALL_TOOL-dotfiles-backup"
    INSTALL_BACKUP_DIR="$(mktemp -d "$INSTALL_STATE_ROOT/$INSTALL_TOOL-dotfiles-backup/$(date +%Y%m%d%H%M%S)-XXXXXX")"
  fi
  backup="$INSTALL_BACKUP_DIR/$rel"
  mkdir -p "$(dirname "$backup")"
  mv "$dest" "$backup"
  echo "backup    $backup"
}

install_run() {
  local i kind src dest previous conflicts=0
  for i in "${!INSTALL_SRC[@]}"; do
    kind="${INSTALL_KIND[$i]}"
    src="${INSTALL_SRC[$i]}"
    dest="$HOME/${INSTALL_DST[$i]}"
    previous="$INSTALL_STATE_DIR/${INSTALL_DST[$i]}"
    if [[ ! -e "$dest" && ! -L "$dest" ]]; then
      continue
    fi
    if { [[ "$kind" == link ]] && [[ -d "$dest" && ! -L "$dest" ]]; } ||
      { [[ "$kind" == file ]] && [[ ! -f "$dest" && ! -L "$dest" ]]; }; then
      echo "error: destination is not a file: $dest" >&2
      conflicts=1
      continue
    fi
    if _install_managed "$kind" "$src" "$dest" "$previous"; then
      continue
    fi
    if [[ "$INSTALL_FORCE" == 0 ]]; then
      echo "conflict: $dest differs from dotfiles or the last installed copy; review it before using --force" >&2
      conflicts=1
    fi
  done
  [[ "$conflicts" == 0 ]] || exit 1

  umask 077
  for i in "${!INSTALL_SRC[@]}"; do
    kind="${INSTALL_KIND[$i]}"
    src="${INSTALL_SRC[$i]}"
    dest="$HOME/${INSTALL_DST[$i]}"
    previous="$INSTALL_STATE_DIR/${INSTALL_DST[$i]}"
    if _install_current "$kind" "$src" "$dest"; then
      if [[ "$kind" == file ]]; then
        chmod "${INSTALL_MODE[$i]}" "$dest"
      fi
      echo "ok        $dest"
    else
      if [[ -e "$dest" || -L "$dest" ]]; then
        _install_backup "$dest" "${INSTALL_DST[$i]}"
      fi
      mkdir -p "$(dirname "$dest")"
      if [[ "$kind" == link ]]; then
        ln -s "$src" "$dest"
      else
        install -m "${INSTALL_MODE[$i]}" "$src" "$dest"
      fi
      echo "copied    $dest"
    fi
    if [[ "$kind" == file ]]; then
      mkdir -p "$(dirname "$previous")"
      install -m 600 "$src" "$previous"
    fi
  done
}
