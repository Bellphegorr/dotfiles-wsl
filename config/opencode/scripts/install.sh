#!/usr/bin/env bash
# Installs OpenCode agents plus shared skills and the agent-workflow-init command as symlinks to the
# dotfiles. Safe to rerun: correct links are kept and different files are moved
# to a backup in ~/.local/state before being replaced.
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
OPENCODE_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
WORKFLOW_DIR="$(cd "$OPENCODE_DIR/../agent-workflow" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
BIN_DIR="$HOME/.local/bin"
# Outside ~/.config/opencode so OpenCode does not load backups as agents/skills.
BACKUP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/opencode-dotfiles-backup/$(date +%Y%m%d%H%M%S)"

link() {
  local src="$1" dest="$2"

  if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
    echo "ok        $dest"
    return
  fi

  mkdir -p "$(dirname "$dest")"

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ -f "$dest" && ! -L "$dest" ]] && cmp -s "$src" "$dest"; then
      rm "$dest"
    else
      local backup="$BACKUP_DIR${dest#"$HOME"}"
      mkdir -p "$(dirname "$backup")"
      mv "$dest" "$backup"
      echo "backup    $backup"
    fi
  fi

  ln -s "$src" "$dest"
  echo "linked    $dest -> $src"
}

link "$OPENCODE_DIR/opencode.jsonc" "$CONFIG_DIR/opencode.jsonc"

# Older installs linked the legacy agents into the V1 `agent/` directory.
# Every agent now lives in `agents/`; remove stale links that point here.
if [[ -d "$CONFIG_DIR/agent" && ! -L "$CONFIG_DIR/agent" ]]; then
  for dest in "$CONFIG_DIR"/agent/*.md; do
    [[ -L "$dest" ]] || continue
    target="$(readlink "$dest" 2>/dev/null || true)"
    case "$target" in
      "$OPENCODE_DIR"/*) rm "$dest" ;;
    esac
  done
  rmdir "$CONFIG_DIR/agent" 2>/dev/null || true
fi

for file in "$OPENCODE_DIR"/agents/*.md; do
  link "$file" "$CONFIG_DIR/agents/$(basename "$file")"
done

for dir in "$WORKFLOW_DIR"/skills/*/; do
  dir="${dir%/}"
  link "$dir" "$CONFIG_DIR/skills/$(basename "$dir")"
done

link "$WORKFLOW_DIR/scripts/init-agent-workflow.sh" "$BIN_DIR/agent-workflow-init"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "warning: $BIN_DIR is not in PATH" >&2 ;;
esac

echo
echo "Done. Restart OpenCode (and T3 Code) to load the changes."
