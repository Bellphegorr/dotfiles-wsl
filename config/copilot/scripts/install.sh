#!/usr/bin/env bash
# Installs personal Copilot agents and shared skills as links to this dotfiles
# checkout. Safe to rerun: correct links are kept, local edits abort the run
# and --force backs them up before replacing.
set -euo pipefail

usage() {
  echo "Usage: bash config/copilot/scripts/install.sh [--force|--verify]"
  echo "Links agents and shared skills into ~/.copilot; --force backs up and replaces local edits."
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
COPILOT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
WORKFLOW_DIR="$(cd "$COPILOT_DIR/../agent-workflow" && pwd)"
REPO="$(cd "$COPILOT_DIR/../.." && pwd)"
AGENT_DIR="$HOME/.copilot/agents"
SKILL_DIR="$HOME/.copilot/skills"
INIT_DIR="$HOME/.local/bin"
# shellcheck source=../../../scripts/install-lib.sh
source "$REPO/scripts/install-lib.sh"

install_begin copilot "$FORCE" "$VERIFY"

for file in "$COPILOT_DIR"/agents/*.agent.md; do
  install_link_path "$file" "$AGENT_DIR/$(basename "$file")"
done
install_prune_links "$AGENT_DIR" "$COPILOT_DIR/agents"

for dir in "$WORKFLOW_DIR"/skills/*/; do
  dir="${dir%/}"
  install_link_path "$dir" "$SKILL_DIR/$(basename "$dir")"
done
install_prune_links "$SKILL_DIR" "$WORKFLOW_DIR/skills"

install_link_path "$WORKFLOW_DIR/scripts/init-agent-workflow.sh" "$INIT_DIR/agent-workflow-init"
install_link_path "$WORKFLOW_DIR/scripts/init-agent-workflow.sh" "$INIT_DIR/copilot-workflow-init"

install_run

if [[ "$VERIFY" == 0 ]]; then
  case ":$PATH:" in
    *":$INIT_DIR:"*) ;;
    *) echo "warning: $INIT_DIR is not in PATH" >&2 ;;
  esac

  echo
  echo "Done. Restart GitHub Copilot CLI to load the custom agent and skills."
fi
