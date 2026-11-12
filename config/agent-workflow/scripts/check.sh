#!/usr/bin/env bash
# Validates the agent workflow config without touching the real HOME:
# script syntax, generated agent profiles, skill frontmatter, guide links,
# and both installers plus the initializer in a disposable HOME.
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
REPO="$(cd "$(dirname "$SCRIPT_PATH")/../../.." && pwd)"
WORKFLOW="$REPO/config/agent-workflow"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }

for script in "$REPO"/config/{opencode,copilot}/scripts/install.sh "$WORKFLOW"/scripts/*.sh; do
  bash -n "$script" || fail "syntax: $script"
done
pass 'script syntax'

"$WORKFLOW/scripts/sync-agents.sh" --check > /dev/null || fail 'agent profiles out of date'
pass 'agent profiles match config/agent-workflow/agents'

declare -A seen=()
for skill in "$WORKFLOW"/skills/*/SKILL.md; do
  frontmatter="$(awk 'NR == 1 && $0 != "---" { exit 1 } NR > 1 && /^---$/ { exit } NR > 1' "$skill")" \
    || fail "missing frontmatter: $skill"
  name="$(sed -n 's/^name:[[:space:]]*//p' <<< "$frontmatter" | tr '[:upper:]' '[:lower:]')"
  grep -Eq '^description:[[:space:]]*[^[:space:]]' <<< "$frontmatter" || fail "missing description: $skill"
  [[ -n "$name" ]] || fail "missing name: $skill"
  [[ -z "${seen[$name]:-}" ]] || fail "duplicate skill name '$name': $skill"
  seen[$name]=1
done
pass "${#seen[@]} skills with unique name and description"

for doc in "$REPO"/README.md "$REPO"/docs/*.md; do
  while IFS= read -r target; do
    [[ "$target" == *://* || "$target" == \#* ]] && continue
    [[ -e "$(dirname "$doc")/${target%%#*}" ]] || fail "broken link in $doc: $target"
  done < <(grep -oE '\]\([^)]+\)' "$doc" | sed -E 's/^\]\(|\)$//g')
done
pass 'local links in README and docs'

export HOME="$TMP/home" XDG_CONFIG_HOME="$TMP/home/.config" XDG_STATE_HOME="$TMP/home/.local/state"
mkdir -p "$XDG_CONFIG_HOME/opencode/agents" "$HOME/.copilot/skills/custom"
echo 'user builder' > "$XDG_CONFIG_HOME/opencode/agents/builder.md"
echo 'user skill' > "$HOME/.copilot/skills/custom/keep.txt"

for round in 1 2; do
  for harness in opencode copilot; do
    bash "$REPO/config/$harness/scripts/install.sh" > "$TMP/$harness-$round.log" 2>&1 \
      || { cat "$TMP/$harness-$round.log" >&2; fail "$harness installer, round $round"; }
  done
done
grep -q '^linked\|^backup' "$TMP/opencode-2.log" "$TMP/copilot-2.log" && fail 'second install was not a no-op'

links_to() { [[ -L "$1" && "$(readlink -f "$1")" == "$(readlink -f "$2")" ]] || fail "link: $1"; }
for skill in "$WORKFLOW"/skills/*/; do
  links_to "$XDG_CONFIG_HOME/opencode/skills/$(basename "$skill")" "$skill"
  links_to "$HOME/.copilot/skills/$(basename "$skill")" "$skill"
done
for agent in "$REPO"/config/opencode/agents/*.md; do
  links_to "$XDG_CONFIG_HOME/opencode/agents/$(basename "$agent")" "$agent"
done
for agent in "$REPO"/config/copilot/agents/*.agent.md; do
  links_to "$HOME/.copilot/agents/$(basename "$agent")" "$agent"
done
links_to "$HOME/.local/bin/agent-workflow-init" "$WORKFLOW/scripts/init-agent-workflow.sh"
grep -rqx 'user builder' "$XDG_STATE_HOME/opencode-dotfiles-backup" || fail 'replaced user file not backed up'
grep -qx 'user skill' "$HOME/.copilot/skills/custom/keep.txt" || fail 'unrelated user skill touched'
pass 'both installers link everything, back up replaced files and are idempotent'

project="$TMP/project"
mkdir -p "$project/.agents/memory"
echo 'existing policy' > "$project/AGENTS.md"
bash "$HOME/.local/bin/agent-workflow-init" "$project" > /dev/null
find "$project" -type f -exec sha256sum {} + | sort > "$TMP/init-1"
bash "$HOME/.local/bin/agent-workflow-init" "$project" > /dev/null
find "$project" -type f -exec sha256sum {} + | sort > "$TMP/init-2"
cmp -s "$TMP/init-1" "$TMP/init-2" || fail 'initializer is not idempotent'
grep -qx 'existing policy' "$project/AGENTS.md" || fail 'initializer overwrote AGENTS.md'
for name in decisions gotchas handoff; do
  cmp -s "$project/.agents/memory/$name.md" "$WORKFLOW/templates/memory/$name.md" || fail "template: $name"
done
pass 'initializer preserves existing files, copies templates and is idempotent'
