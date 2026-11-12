#!/usr/bin/env bash
# Writes each shared agent body from config/agent-workflow/agents/<name>.md into
# the harness profiles, keeping each profile's own frontmatter.
# Usage: sync-agents.sh [--check]   (--check only reports profiles out of date)
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
WORKFLOW_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
CONFIG_DIR="$(dirname "$WORKFLOW_DIR")"
check=false
[[ "${1:-}" == "--check" ]] && check=true

stale=0
for source in "$WORKFLOW_DIR"/agents/*.md; do
  name="$(basename "$source" .md)"
  relative="${source#"$CONFIG_DIR"/}"
  for profile in "$CONFIG_DIR/opencode/agents/$name.md" "$CONFIG_DIR/copilot/agents/$name.agent.md"; do
    [[ -f "$profile" ]] || { echo "missing   $profile" >&2; stale=1; continue; }
    head -n1 "$profile" | grep -qx -- '---' || { echo "no frontmatter: $profile" >&2; exit 1; }

    expected="$(
      awk 'NR == 1 { print; next } { print } /^---$/ { exit }' "$profile"
      echo
      echo "<!-- Generated from config/$relative by sync-agents.sh; edit that file. -->"
      echo
      cat "$source"
    )"
    if [[ "$(cat "$profile")" == "$expected" ]]; then
      echo "ok        $profile"
    elif $check; then
      echo "stale     $profile" >&2
      stale=1
    else
      printf '%s\n' "$expected" > "$profile"
      echo "updated   $profile"
    fi
  done
done

if [[ "$stale" -ne 0 ]]; then
  echo "Run config/agent-workflow/scripts/sync-agents.sh to update the profiles." >&2
  exit 1
fi
