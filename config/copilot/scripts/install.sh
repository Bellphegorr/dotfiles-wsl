#!/usr/bin/env bash
# Install personal Copilot agents and skills as links to this dotfiles checkout.
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
COPILOT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
WORKFLOW_DIR="$(cd "$COPILOT_DIR/../agent-workflow" && pwd)"
AGENT_DIR="$HOME/.copilot/agents"
SKILL_DIR="$HOME/.copilot/skills"
INIT_DIR="$HOME/.local/bin"
BACKUP_DIR="$HOME/.local/state/copilot-dotfiles-backup/$(date +%Y%m%d%H%M%S)"

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

for file in "$COPILOT_DIR"/agents/*.agent.md; do
  link "$file" "$AGENT_DIR/$(basename "$file")"
done

for dir in "$WORKFLOW_DIR"/skills/*/; do
  dir="${dir%/}"
  link "$dir" "$SKILL_DIR/$(basename "$dir")"
done

link "$WORKFLOW_DIR/scripts/init-agent-workflow.sh" "$INIT_DIR/agent-workflow-init"
link "$WORKFLOW_DIR/scripts/init-agent-workflow.sh" "$INIT_DIR/copilot-workflow-init"

case ":$PATH:" in
  *":$INIT_DIR:"*) ;;
  *) echo "warning: $INIT_DIR is not in PATH" >&2 ;;
esac

echo
echo "Done. Restart GitHub Copilot CLI to load the custom agent and skills."
