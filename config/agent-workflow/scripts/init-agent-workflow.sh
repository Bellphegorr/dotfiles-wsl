#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
WORKFLOW_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$WORKFLOW_DIR/templates"

target="${1:-.}"

if [[ ! -d "$target" ]]; then
  echo "directory does not exist: $target" >&2
  exit 1
fi

cd "$target"

mkdir -p .agents/memory .agents/work

if [[ -f AGENTS.md ]]; then
  echo "AGENTS.md already exists; not overwriting."
else
  cp "$TEMPLATES_DIR/AGENTS.md" AGENTS.md
  echo "created AGENTS.md"
fi

for file in decisions gotchas handoff; do
  dest=".agents/memory/$file.md"
  if [[ -f "$dest" ]]; then
    echo "$dest already exists; not overwriting."
  else
    cp "$TEMPLATES_DIR/memory/$file.md" "$dest"
    echo "created $dest"
  fi
done

echo
echo "Done. Next steps:"
echo "1. Fill in commands and invariants in AGENTS.md."
echo "2. Open your coding harness and choose its builder agent."
echo "3. Large task: ask it to use the plan skill."
echo "4. Execute: implement skill. Review: review skill."
echo "5. Ship: ship skill, only when you ask."
