#!/usr/bin/env bash
# Shared copy/link/conflict engine for the dotfiles installers.
#
# Usage in a per-tool installer:
#   install_begin <tool> <force 0|1> [verify 0|1]
#   install_file <src> <target relative to $HOME> <mode>
#   install_link <src> <target relative to $HOME>
#   install_file_path <src> <absolute target> <mode>
#   install_link_path <src> <absolute target>
#   install_prune_links <dir> <root>
#   install_run
#
# install_run checks every destination first. Unchanged files are "ok";
# files replaced by a previous install are updated with a backup; anything
# else is a conflict that aborts the whole run unless --force is given. The
# last installed copy of each file is kept under
# $XDG_STATE_HOME/<tool>-dotfiles/installed to tell managed files from
# local edits.
#
# With verify=1, install_run writes nothing and reports ok, missing, outdated,
# differs or stale for each destination, then returns 1 when anything is out of
# sync. Stale links are links under a managed directory that point into the
# checkout but whose target no longer exists; a normal run prunes them.

declare -a INSTALL_SRC=() INSTALL_DST=() INSTALL_MODE=() INSTALL_KIND=() INSTALL_PRUNE=()
INSTALL_TOOL=""
INSTALL_FORCE=0
INSTALL_VERIFY=0
INSTALL_STATE_ROOT=""
INSTALL_STATE_DIR=""
INSTALL_BACKUP_DIR=""

install_begin() {
  INSTALL_TOOL="$1"
  INSTALL_FORCE="${2:-0}"
  INSTALL_VERIFY="${3:-0}"
  INSTALL_SRC=()
  INSTALL_DST=()
  INSTALL_MODE=()
  INSTALL_KIND=()
  INSTALL_PRUNE=()
  INSTALL_STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}"
  INSTALL_STATE_DIR="$INSTALL_STATE_ROOT/$INSTALL_TOOL-dotfiles/installed"
  INSTALL_BACKUP_DIR=""
}

_install_add() { # kind src absolute-dest mode
  local kind="$1" src="$2" dest="${3%/}" mode="${4:-}"
  if [[ -z "$dest" || "$dest" != /* ]]; then
    echo "error: destination must be absolute: $3" >&2
    return 1
  fi
  INSTALL_SRC+=("$src")
  INSTALL_DST+=("$dest")
  INSTALL_MODE+=("$mode")
  INSTALL_KIND+=("$kind")
}

install_file() {
  _install_add file "$1" "$HOME/$2" "$3"
}

install_link() {
  _install_add link "$1" "$HOME/$2"
}

install_file_path() {
  _install_add file "$1" "$2" "$3"
}

install_link_path() {
  _install_add link "$1" "$2"
}

# Record links under <dir> that point into <root> but whose target disappeared,
# such as after a skill or agent rename. Unrelated links are left untouched.
install_prune_links() { # dir root
  local dir="${1%/}" root="${2%/}" dest target
  [[ -d "$dir" ]] || return 0
  for dest in "$dir"/*; do
    [[ -L "$dest" ]] || continue
    target="$(readlink "$dest" 2>/dev/null || true)"
    case "$target" in
      "$root"/*)
        if [[ ! -e "$target" ]]; then
          INSTALL_PRUNE+=("$dest")
        fi
        ;;
    esac
  done
}

# Already up to date: same content (files) or same target (links).
_install_current() { # kind src dest
  case "$1" in
    file) [[ -f "$3" && ! -L "$3" ]] && cmp -s "$2" "$3" ;;
    link) [[ -L "$3" && "$(readlink -f "$3")" == "$(readlink -f "$2")" ]] ;;
  esac
}

# State and backup paths keep the relative path under $HOME and use an
# _external/ prefix for destinations outside it.
_install_key() { # absolute dest
  if [[ "$1" == "$HOME"/* ]]; then
    printf '%s\n' "${1#"$HOME"/}"
  else
    printf '_external/%s\n' "${1#/}"
  fi
}

_install_status() { # kind src dest previous
  local kind="$1" src="$2" dest="$3" previous="$4"
  if [[ ! -e "$dest" && ! -L "$dest" ]]; then
    printf 'missing\n'
    return 0
  fi
  if [[ "$kind" == link && -d "$dest" && ! -L "$dest" ]] ||
    [[ "$kind" == file && ! -f "$dest" && ! -L "$dest" ]]; then
    if [[ -d "$dest" && ! -L "$dest" ]]; then
      printf 'conflict-directory\n'
    else
      printf 'conflict-type\n'
    fi
    return 0
  fi
  if _install_current "$kind" "$src" "$dest"; then
    printf 'ok\n'
    return 0
  fi
  # A copied file that already matches a file link source is safe to relink.
  if [[ "$kind" == link && -f "$src" && -f "$dest" && ! -L "$dest" ]] &&
    cmp -s "$src" "$dest"; then
    printf 'outdated\n'
    return 0
  fi
  if [[ "$kind" == file && -f "$dest" && ! -L "$dest" && -f "$previous" && ! -L "$previous" ]] \
    && cmp -s "$previous" "$dest"; then
    printf 'outdated\n'
    return 0
  fi
  printf 'differs\n'
}

_install_backup() { # absolute dest
  local dest="$1" rel backup
  rel="$(_install_key "$dest")"
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
  local i kind src dest previous status
  local ok=0 missing=0 outdated=0 different=0 stale=0 conflicts=0
  local -a item_status=()

  for i in "${!INSTALL_SRC[@]}"; do
    kind="${INSTALL_KIND[$i]}"
    src="${INSTALL_SRC[$i]}"
    dest="${INSTALL_DST[$i]}"
    previous="$INSTALL_STATE_DIR/$(_install_key "$dest")"
    status="$(_install_status "$kind" "$src" "$dest" "$previous")"
    item_status+=("$status")
    case "$status" in
      ok) ok=$((ok + 1)) ;;
      missing) missing=$((missing + 1)) ;;
      outdated) outdated=$((outdated + 1)) ;;
      differs | conflict-*) different=$((different + 1)) ;;
      *) echo "error: unknown install status: $status" >&2; return 1 ;;
    esac
  done
  stale="${#INSTALL_PRUNE[@]}"

  if [[ "$INSTALL_VERIFY" == 1 ]]; then
    for i in "${!INSTALL_DST[@]}"; do
      printf '%-9s %s\n' "${item_status[$i]}" "${INSTALL_DST[$i]}"
    done
    for dest in "${INSTALL_PRUNE[@]}"; do
      printf '%-9s %s\n' 'stale' "$dest"
    done
    echo
    echo "Verify: $ok ok, $missing missing, $outdated outdated, $different different, $stale stale."
    [[ $((missing + outdated + different + stale)) -eq 0 ]]
    return
  fi

  for i in "${!INSTALL_SRC[@]}"; do
    status="${item_status[$i]}"
    dest="${INSTALL_DST[$i]}"
    case "$status" in
      conflict-*)
        echo "error: destination is not replaceable: $dest ($status)" >&2
        conflicts=1
        ;;
      differs)
        if [[ "$INSTALL_FORCE" == 0 ]]; then
          echo "conflict: $dest differs from dotfiles or the last installed copy; review it before using --force" >&2
          conflicts=1
        fi
        ;;
    esac
  done
  [[ "$conflicts" == 0 ]] || return 1

  umask 077
  for i in "${!INSTALL_SRC[@]}"; do
    kind="${INSTALL_KIND[$i]}"
    src="${INSTALL_SRC[$i]}"
    dest="${INSTALL_DST[$i]}"
    previous="$INSTALL_STATE_DIR/$(_install_key "$dest")"
    status="${item_status[$i]}"
    if [[ "$status" == ok ]]; then
      if [[ "$kind" == file ]]; then
        chmod "${INSTALL_MODE[$i]}" "$dest"
      fi
      echo "ok        $dest"
      continue
    fi
    if [[ -e "$dest" || -L "$dest" ]]; then
      _install_backup "$dest"
    fi
    mkdir -p "$(dirname "$dest")"
    if [[ "$kind" == link ]]; then
      ln -s "$src" "$dest"
      echo "linked    $dest"
    else
      install -m "${INSTALL_MODE[$i]}" "$src" "$dest"
      echo "copied    $dest"
      mkdir -p "$(dirname "$previous")"
      install -m 600 "$src" "$previous"
    fi
  done
  for dest in "${INSTALL_PRUNE[@]}"; do
    rm "$dest"
    echo "pruned    $dest"
  done
}
