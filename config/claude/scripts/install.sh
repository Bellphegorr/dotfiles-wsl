#!/usr/bin/env bash
# Installs the shared Builder agent and skills into a Claude Code config
# directory as links to this dotfiles checkout.
#
# Defaults to ~/.claude. Set CLAUDE_CONFIG_DIR to target another Claude
# instance, for example the T3 Code Claude + OpenCode Go instance:
#
#   CLAUDE_CONFIG_DIR="$HOME/.claude_opencode_go" \
#     bash config/claude/scripts/install.sh
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
CLAUDE_PROFILE_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
WORKFLOW_DIR="$(cd "$CLAUDE_PROFILE_DIR/../agent-workflow" && pwd)"
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CONFIG_DIR="${CONFIG_DIR/#\~/$HOME}"
AGENT_DIR="$CONFIG_DIR/agents"
SKILL_DIR="$CONFIG_DIR/skills"
BIN_DIR="$HOME/.local/bin"
BACKUP_DIR="$HOME/.local/state/claude-dotfiles-backup/$(date +%Y%m%d%H%M%S)"

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

# Remove links owned by this checkout whose source no longer exists, such as
# after a skill or agent rename. Unrelated user files are left untouched.
prune_links() {
  local dir="$1" root="$2" dest target

  [[ -d "$dir" ]] || return 0
  for dest in "$dir"/*; do
    [[ -L "$dest" ]] || continue
    target="$(readlink "$dest" 2>/dev/null || true)"
    case "$target" in
      "$root"/*)
        if [[ ! -e "$target" ]]; then
          rm "$dest"
          echo "pruned    $dest -> $target"
        fi
        ;;
    esac
  done
}

for file in "$CLAUDE_PROFILE_DIR"/agents/*.md; do
  link "$file" "$AGENT_DIR/$(basename "$file")"
done
prune_links "$AGENT_DIR" "$CLAUDE_PROFILE_DIR/agents"

for dir in "$WORKFLOW_DIR"/skills/*/; do
  dir="${dir%/}"
  link "$dir" "$SKILL_DIR/$(basename "$dir")"
done
prune_links "$SKILL_DIR" "$WORKFLOW_DIR/skills"

link "$WORKFLOW_DIR/scripts/init-agent-workflow.sh" "$BIN_DIR/agent-workflow-init"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "warning: $BIN_DIR is not in PATH" >&2 ;;
esac

echo
echo "Done in $CONFIG_DIR."
echo "Use Builder as the main Claude Code agent with: claude --agent builder"
echo "In T3 Code, add that flag to the Claude instance's Launch arguments."
echo "Restart Claude Code (and T3 Code) to load the agent and skills."
