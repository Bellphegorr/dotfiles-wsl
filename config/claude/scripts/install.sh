#!/usr/bin/env bash
# Installs the shared Builder agent and skills into a Claude Code config
# directory as links to this dotfiles checkout. Safe to rerun: correct links
# are kept, local edits abort the run and --force backs them up before
# replacing.
#
# Defaults to ~/.claude. Set CLAUDE_CONFIG_DIR to target another Claude
# instance, for example the T3 Code Claude + OpenCode Go instance:
#
#   CLAUDE_CONFIG_DIR="$HOME/.claude_opencode_go" \
#     bash config/claude/scripts/install.sh
set -euo pipefail

usage() {
  echo "Usage: bash config/claude/scripts/install.sh [--force|--verify]"
  echo "Links agents and shared skills into \${CLAUDE_CONFIG_DIR:-~/.claude}; --force backs up and replaces local edits."
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
CLAUDE_PROFILE_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
WORKFLOW_DIR="$(cd "$CLAUDE_PROFILE_DIR/../agent-workflow" && pwd)"
REPO="$(cd "$CLAUDE_PROFILE_DIR/../.." && pwd)"
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CONFIG_DIR="${CONFIG_DIR/#\~/$HOME}"
AGENT_DIR="$CONFIG_DIR/agents"
SKILL_DIR="$CONFIG_DIR/skills"
BIN_DIR="$HOME/.local/bin"
# shellcheck source=../../../scripts/install-lib.sh
source "$REPO/scripts/install-lib.sh"

install_begin claude "$FORCE" "$VERIFY"

for file in "$CLAUDE_PROFILE_DIR"/agents/*.md; do
  install_link_path "$file" "$AGENT_DIR/$(basename "$file")"
done
install_prune_links "$AGENT_DIR" "$CLAUDE_PROFILE_DIR/agents"

for dir in "$WORKFLOW_DIR"/skills/*/; do
  dir="${dir%/}"
  install_link_path "$dir" "$SKILL_DIR/$(basename "$dir")"
done
install_prune_links "$SKILL_DIR" "$WORKFLOW_DIR/skills"

install_link_path "$WORKFLOW_DIR/scripts/init-agent-workflow.sh" "$BIN_DIR/agent-workflow-init"

install_run

if [[ "$VERIFY" == 0 ]]; then
  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) echo "warning: $BIN_DIR is not in PATH" >&2 ;;
  esac

  echo
  echo "Done in $CONFIG_DIR."
  echo "Use Builder as the main Claude Code agent with: claude --agent builder"
  echo "In T3 Code, add that flag to the Claude instance's Launch arguments."
  echo "Restart Claude Code (and T3 Code) to load the agent and skills."
fi
