#!/usr/bin/env bash
# Validates the agent workflow config without touching the real HOME:
# script syntax, generated agent profiles, skill frontmatter, guide links,
# and the installers plus the initializer in disposable HOME directories.
set -euo pipefail

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
REPO="$(cd "$(dirname "$SCRIPT_PATH")/../../.." && pwd)"
WORKFLOW="$REPO/config/agent-workflow"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }

for script in "$REPO"/scripts/install-shell.sh "$REPO"/config/{opencode,copilot}/scripts/install.sh "$WORKFLOW"/scripts/*.sh; do
  bash -n "$script" || fail "syntax: $script"
done
pass 'script syntax'

"$WORKFLOW/scripts/sync-agents.sh" --check > /dev/null || fail 'agent profiles out of date'
pass 'agent profiles match config/agent-workflow/agents'

declare -A seen=()
# Copilot CLI reserves these names for built-in slash commands, so a skill with
# one of them is never exposed as a command.
reserved_names=(plan review)
for skill in "$WORKFLOW"/skills/*/SKILL.md; do
  frontmatter="$(awk 'NR == 1 && $0 != "---" { exit 1 } NR > 1 && /^---$/ { exit } NR > 1' "$skill")" \
    || fail "missing frontmatter: $skill"
  name="$(sed -n 's/^name:[[:space:]]*//p' <<< "$frontmatter")"
  dir="$(basename "$(dirname "$skill")")"
  grep -Eq '^description:[[:space:]]*[^[:space:]]' <<< "$frontmatter" || fail "missing description: $skill"
  [[ -n "$name" ]] || fail "missing name: $skill"
  [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || fail "invalid skill name '$name': $skill"
  [[ "$name" == "$dir" ]] || fail "skill name '$name' does not match directory '$dir': $skill"
  for reserved in "${reserved_names[@]}"; do
    [[ "$name" != "$reserved" ]] || fail "reserved skill name '$name': $skill"
  done
  [[ -z "${seen[$name]:-}" ]] || fail "duplicate skill name '$name': $skill"
  seen[$name]=1
done
pass "${#seen[@]} skills with valid, unique names and descriptions"

for doc in "$REPO"/README.md "$REPO"/docs/*.md; do
  while IFS= read -r target; do
    [[ "$target" == *://* || "$target" == \#* ]] && continue
    [[ -e "$(dirname "$doc")/${target%%#*}" ]] || fail "broken link in $doc: $target"
  done < <(grep -oE '\]\([^)]+\)' "$doc" | sed -E 's/^\]\(|\)$//g')
done
pass 'local links in README and docs'

export HOME="$TMP/home" XDG_CONFIG_HOME="$TMP/home/.config" XDG_STATE_HOME="$TMP/home/.local/state"
mkdir -p "$XDG_CONFIG_HOME/opencode/agents" "$XDG_CONFIG_HOME/opencode/skills" \
  "$HOME/.copilot/agents" "$HOME/.copilot/skills/custom"
echo 'user builder' > "$XDG_CONFIG_HOME/opencode/agents/builder.md"
echo 'user skill' > "$HOME/.copilot/skills/custom/keep.txt"
# Renamed skills and retired agents leave dangling links in existing installs.
ln -s "$WORKFLOW/skills/plan" "$XDG_CONFIG_HOME/opencode/skills/plan"
ln -s "$WORKFLOW/skills/review" "$HOME/.copilot/skills/review"
ln -s "$REPO/config/opencode/agents/planner-0.2.md" "$XDG_CONFIG_HOME/opencode/agents/planner-0.2.md"
ln -s "$REPO/config/copilot/agents/planner.agent.md" "$HOME/.copilot/agents/planner.agent.md"

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
for stale in "$XDG_CONFIG_HOME/opencode/skills/plan" "$HOME/.copilot/skills/review" \
  "$XDG_CONFIG_HOME/opencode/agents/planner-0.2.md" "$HOME/.copilot/agents/planner.agent.md"; do
  [[ ! -e "$stale" && ! -L "$stale" ]] || fail "stale link not pruned: $stale"
done
grep -rqx 'user builder' "$XDG_STATE_HOME/opencode-dotfiles-backup" || fail 'replaced user file not backed up'
grep -qx 'user skill' "$HOME/.copilot/skills/custom/keep.txt" || fail 'unrelated user skill touched'
pass 'both installers link everything, prune stale links, back up replaced files and are idempotent'

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

shell_repo="$TMP/shell-repo"
mkdir -p "$shell_repo/scripts" "$shell_repo/config/tmux/scripts"
cp "$REPO/scripts/install-shell.sh" "$shell_repo/scripts/"
cp "$REPO/bashrc" "$shell_repo/bashrc"
cp "$REPO/config/tmux/scripts/startup.sh" "$shell_repo/config/tmux/scripts/"
shell_installer="$shell_repo/scripts/install-shell.sh"
export HOME="$TMP/shell-empty-home" XDG_STATE_HOME="$TMP/shell-empty-state"
bash "$shell_installer" > "$TMP/shell-empty.log" 2>&1
cmp -s "$HOME/.bashrc" "$shell_repo/bashrc" || fail 'fresh bashrc not installed'
cmp -s "$HOME/.config/tmux/scripts/startup.sh" "$shell_repo/config/tmux/scripts/startup.sh" \
  || fail 'fresh tmux startup not installed'
[[ ! -e "$XDG_STATE_HOME/shell-dotfiles-backup" ]] || fail 'fresh install created unnecessary backup'
export HOME="$TMP/shell-home" XDG_STATE_HOME="$TMP/shell-state"
mkdir -p "$HOME"
echo 'local bashrc' > "$HOME/.bashrc"
if bash "$shell_installer" > "$TMP/shell-conflict.log" 2>&1; then
  fail 'shell installer accepted an unmanaged local file'
fi
grep -qx 'local bashrc' "$HOME/.bashrc" || fail 'shell conflict changed bashrc'
[[ ! -e "$HOME/.config" && ! -e "$XDG_STATE_HOME" ]] || fail 'shell conflict partially installed files'
bash "$shell_installer" --force > "$TMP/shell-1.log" 2>&1
grep -rqx 'local bashrc' "$XDG_STATE_HOME/shell-dotfiles-backup" || fail 'shell backup missing'
bash "$shell_installer" > "$TMP/shell-2.log" 2>&1
grep -q '^copied\|^backup' "$TMP/shell-2.log" && fail 'second shell install was not a no-op'
cmp -s "$HOME/.bashrc" "$shell_repo/bashrc" || fail 'bashrc not installed'
cmp -s "$HOME/.config/tmux/scripts/startup.sh" "$shell_repo/config/tmux/scripts/startup.sh" \
  || fail 'tmux startup not installed'
[[ -x "$HOME/.config/tmux/scripts/startup.sh" && ! -L "$HOME/.bashrc" ]] || fail 'shell install permissions or copy'

echo '# repo update' >> "$shell_repo/bashrc"
bash "$shell_installer" > "$TMP/shell-update.log" 2>&1
cmp -s "$HOME/.bashrc" "$shell_repo/bashrc" || fail 'managed bashrc not updated'
find "$XDG_STATE_HOME/shell-dotfiles-backup" -name .bashrc -exec cmp -s "$REPO/bashrc" {} \; -print \
  | grep -q . || fail 'managed update not backed up'
echo '# another repo update' >> "$shell_repo/bashrc"
echo '# local edit' >> "$HOME/.config/tmux/scripts/startup.sh"
if bash "$shell_installer" > "$TMP/shell-edited.log" 2>&1; then
  fail 'shell installer overwrote a local edit'
fi
grep -qx '# local edit' "$HOME/.config/tmux/scripts/startup.sh" || fail 'local edit lost'
grep -qx '# another repo update' "$HOME/.bashrc" && fail 'conflict allowed a partial update'
bash "$shell_installer" --force > "$TMP/shell-force.log" 2>&1
grep -rqx '# local edit' "$XDG_STATE_HOME/shell-dotfiles-backup" || fail 'local edit not backed up'

rm "$HOME/.bashrc"
echo 'external file' > "$TMP/external-bashrc"
ln -s "$TMP/external-bashrc" "$HOME/.bashrc"
if bash "$shell_installer" > "$TMP/shell-link.log" 2>&1; then
  fail 'shell installer accepted an unmanaged symlink'
fi
bash "$shell_installer" --force > "$TMP/shell-link-force.log" 2>&1
grep -qx 'external file' "$TMP/external-bashrc" || fail 'symlink target changed'
[[ ! -L "$HOME/.bashrc" ]] || fail 'symlink not replaced by a copy'
find "$XDG_STATE_HOME/shell-dotfiles-backup" -type l -name .bashrc -print \
  | grep -q . || fail 'symlink not backed up'
rm "$HOME/.bashrc"
mkdir "$HOME/.bashrc"
if bash "$shell_installer" --force > "$TMP/shell-directory.log" 2>&1; then
  fail 'shell installer replaced a directory'
fi
[[ -d "$HOME/.bashrc" ]] || fail 'shell installer changed a directory'
pass 'shell installer protects local edits, backs up replacements, updates managed copies and is idempotent'
