#!/usr/bin/env bash
# Installs OpenCode agents plus shared skills, opencode.jsonc and the
# agent-workflow-init command as symlinks to the dotfiles. Safe to rerun:
# correct links are kept, local edits abort the run and --force backs them up
# before replacing.
set -euo pipefail

usage() {
  echo "Usage: bash config/opencode/scripts/install.sh [--force|--verify]"
  echo "Links opencode.jsonc, agents and shared skills; --force replaces local edits after backing them up."
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
OPENCODE_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
WORKFLOW_DIR="$(cd "$OPENCODE_DIR/../agent-workflow" && pwd)"
REPO="$(cd "$OPENCODE_DIR/../.." && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
BIN_DIR="$HOME/.local/bin"
# shellcheck source=../../../scripts/install-lib.sh
source "$REPO/scripts/install-lib.sh"

install_begin opencode "$FORCE" "$VERIFY"

install_link_path "$OPENCODE_DIR/opencode.jsonc" "$CONFIG_DIR/opencode.jsonc"

for file in "$OPENCODE_DIR"/agents/*.md; do
  install_link_path "$file" "$CONFIG_DIR/agents/$(basename "$file")"
done
install_prune_links "$CONFIG_DIR/agents" "$OPENCODE_DIR/agents"

for dir in "$WORKFLOW_DIR"/skills/*/; do
  dir="${dir%/}"
  install_link_path "$dir" "$CONFIG_DIR/skills/$(basename "$dir")"
done
install_prune_links "$CONFIG_DIR/skills" "$WORKFLOW_DIR/skills"

install_link_path "$WORKFLOW_DIR/scripts/init-agent-workflow.sh" "$BIN_DIR/agent-workflow-init"

install_run

if [[ "$VERIFY" == 0 ]]; then
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

  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) echo "warning: $BIN_DIR is not in PATH" >&2 ;;
  esac

  echo
  echo "Done. Restart OpenCode (and T3 Code) to load the changes."
fi
