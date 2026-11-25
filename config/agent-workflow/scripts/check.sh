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

for script in "$REPO"/scripts/install-lib.sh \
  "$REPO"/install.sh \
  "$REPO"/config/shell/bashrc "$REPO"/config/shell/profile \
  "$REPO"/config/{shell,tmux,opencode,copilot,claude,t3code}/scripts/install.sh \
  "$REPO"/config/git/configure-gcm.sh \
  "$REPO"/config/tmux/scripts/startup.sh "$REPO"/config/tmux/scripts/mksession.sh \
  "$REPO"/config/tmux/scripts/autostart.sh \
  "$WORKFLOW"/scripts/*.sh; do
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
export CLAUDE_CONFIG_DIR="$HOME/.claude"
mkdir -p "$XDG_CONFIG_HOME/opencode/agents" "$XDG_CONFIG_HOME/opencode/skills" \
  "$HOME/.copilot/agents" "$HOME/.copilot/skills/custom" \
  "$HOME/.claude/agents" "$HOME/.claude/skills/custom"
echo 'user builder' > "$XDG_CONFIG_HOME/opencode/agents/builder.md"
echo 'user copilot agent' > "$HOME/.copilot/agents/builder.agent.md"
echo 'user skill' > "$HOME/.copilot/skills/custom/keep.txt"
echo 'user claude builder' > "$HOME/.claude/agents/builder.md"
echo 'user claude skill' > "$HOME/.claude/skills/custom/keep.txt"
# Renamed skills and retired agents leave dangling links in existing installs.
ln -s "$WORKFLOW/skills/plan" "$XDG_CONFIG_HOME/opencode/skills/plan"
ln -s "$WORKFLOW/skills/review" "$HOME/.copilot/skills/review"
ln -s "$WORKFLOW/skills/plan" "$HOME/.claude/skills/plan"
ln -s "$REPO/config/opencode/agents/planner-0.2.md" "$XDG_CONFIG_HOME/opencode/agents/planner-0.2.md"
ln -s "$REPO/config/copilot/agents/planner.agent.md" "$HOME/.copilot/agents/planner.agent.md"
ln -s "$REPO/config/claude/agents/planner.md" "$HOME/.claude/agents/planner.md"

# Verify is read-only and reports missing targets and stale links.
for harness in opencode copilot claude; do
  if bash "$REPO/config/$harness/scripts/install.sh" --verify > "$TMP/$harness-verify-fresh.log" 2>&1; then
    fail "$harness verify accepted a fresh HOME"
  fi
  grep -q '^missing' "$TMP/$harness-verify-fresh.log" || fail "$harness verify did not report missing targets"
  grep -q '^stale' "$TMP/$harness-verify-fresh.log" || fail "$harness verify did not report stale links"
done
[[ ! -e "$HOME/.local/bin/agent-workflow-init" && ! -L "$HOME/.local/bin/agent-workflow-init" ]] \
  || fail 'verify installed a link'
[[ ! -e "$XDG_STATE_HOME" ]] || fail 'verify wrote state'
pass 'harness verify is read-only and reports missing targets and stale links'

# Unmanaged destinations abort the run before any write.
for harness in opencode copilot claude; do
  if bash "$REPO/config/$harness/scripts/install.sh" > "$TMP/$harness-conflict.log" 2>&1; then
    fail "$harness installer accepted unmanaged local files"
  fi
  grep -q '^conflict:' "$TMP/$harness-conflict.log" || fail "$harness conflict was not reported"
done
grep -qx 'user builder' "$XDG_CONFIG_HOME/opencode/agents/builder.md" || fail 'opencode conflict changed a user file'
grep -qx 'user copilot agent' "$HOME/.copilot/agents/builder.agent.md" || fail 'copilot conflict changed a user file'
grep -qx 'user claude builder' "$HOME/.claude/agents/builder.md" || fail 'claude conflict changed a user file'
[[ ! -e "$HOME/.local/bin/agent-workflow-init" && ! -L "$HOME/.local/bin/agent-workflow-init" ]] \
  || fail 'conflict partially installed a link'
[[ ! -e "$XDG_STATE_HOME" ]] || fail 'conflict created state'
pass 'harness installers abort on local edits before writing'

for harness in opencode copilot claude; do
  bash "$REPO/config/$harness/scripts/install.sh" --force > "$TMP/$harness-1.log" 2>&1 \
    || { cat "$TMP/$harness-1.log" >&2; fail "$harness installer --force"; }
  bash "$REPO/config/$harness/scripts/install.sh" > "$TMP/$harness-2.log" 2>&1 \
    || { cat "$TMP/$harness-2.log" >&2; fail "$harness installer, second run"; }
done
grep -q '^linked\|^backup' "$TMP/opencode-2.log" "$TMP/copilot-2.log" "$TMP/claude-2.log" \
  && fail 'second install was not a no-op'

links_to() { [[ -L "$1" && "$(readlink -f "$1")" == "$(readlink -f "$2")" ]] || fail "link: $1"; }
for skill in "$WORKFLOW"/skills/*/; do
  links_to "$XDG_CONFIG_HOME/opencode/skills/$(basename "$skill")" "$skill"
  links_to "$HOME/.copilot/skills/$(basename "$skill")" "$skill"
  links_to "$HOME/.claude/skills/$(basename "$skill")" "$skill"
done
for agent in "$REPO"/config/opencode/agents/*.md; do
  links_to "$XDG_CONFIG_HOME/opencode/agents/$(basename "$agent")" "$agent"
done
for agent in "$REPO"/config/copilot/agents/*.agent.md; do
  links_to "$HOME/.copilot/agents/$(basename "$agent")" "$agent"
done
for agent in "$REPO"/config/claude/agents/*.md; do
  links_to "$HOME/.claude/agents/$(basename "$agent")" "$agent"
done
links_to "$HOME/.local/bin/agent-workflow-init" "$WORKFLOW/scripts/init-agent-workflow.sh"
links_to "$HOME/.local/bin/copilot-workflow-init" "$WORKFLOW/scripts/init-agent-workflow.sh"
links_to "$XDG_CONFIG_HOME/opencode/opencode.jsonc" "$REPO/config/opencode/opencode.jsonc"
for stale in "$XDG_CONFIG_HOME/opencode/skills/plan" "$HOME/.copilot/skills/review" \
  "$HOME/.claude/skills/plan" "$XDG_CONFIG_HOME/opencode/agents/planner-0.2.md" \
  "$HOME/.copilot/agents/planner.agent.md" "$HOME/.claude/agents/planner.md"; do
  [[ ! -e "$stale" && ! -L "$stale" ]] || fail "stale link not pruned: $stale"
done
grep -rqx 'user builder' "$XDG_STATE_HOME/opencode-dotfiles-backup" || fail 'replaced user file not backed up'
grep -rqx 'user copilot agent' "$XDG_STATE_HOME/copilot-dotfiles-backup" || fail 'replaced Copilot user file not backed up'
grep -qx 'user skill' "$HOME/.copilot/skills/custom/keep.txt" || fail 'unrelated user skill touched'
grep -rqx 'user claude builder' "$XDG_STATE_HOME/claude-dotfiles-backup" || fail 'replaced Claude user file not backed up'
grep -qx 'user claude skill' "$HOME/.claude/skills/custom/keep.txt" || fail 'unrelated Claude skill touched'

for harness in opencode copilot claude; do
  bash "$REPO/config/$harness/scripts/install.sh" --verify > "$TMP/$harness-verify-clean.log" 2>&1 \
    || { cat "$TMP/$harness-verify-clean.log" >&2; fail "$harness verify after install"; }
  grep -q '0 missing, 0 outdated, 0 different, 0 stale' "$TMP/$harness-verify-clean.log" \
    || fail "$harness verify summary is not clean"
done

rm "$XDG_CONFIG_HOME/opencode/opencode.jsonc"
if bash "$REPO/config/opencode/scripts/install.sh" --verify > "$TMP/opencode-verify-missing.log" 2>&1; then
  fail 'opencode verify accepted a missing link'
fi
grep -q '^missing.*opencode.jsonc' "$TMP/opencode-verify-missing.log" || fail 'opencode verify did not report a missing link'
bash "$REPO/config/opencode/scripts/install.sh" > "$TMP/opencode-repair.log" 2>&1 \
  || { cat "$TMP/opencode-repair.log" >&2; fail 'opencode did not repair a missing link without --force'; }

rm "$XDG_CONFIG_HOME/opencode/opencode.jsonc"
cp "$REPO/config/opencode/opencode.jsonc" "$XDG_CONFIG_HOME/opencode/opencode.jsonc"
if bash "$REPO/config/opencode/scripts/install.sh" --verify > "$TMP/opencode-verify-copy.log" 2>&1; then
  fail 'opencode verify accepted an identical copied link source'
fi
grep -q '^outdated.*opencode.jsonc' "$TMP/opencode-verify-copy.log" || fail 'opencode verify did not report an identical copy as outdated'
bash "$REPO/config/opencode/scripts/install.sh" > "$TMP/opencode-relink.log" 2>&1 \
  || { cat "$TMP/opencode-relink.log" >&2; fail 'opencode did not relink an identical copy without --force'; }
links_to "$XDG_CONFIG_HOME/opencode/opencode.jsonc" "$REPO/config/opencode/opencode.jsonc"

ln -sfn /tmp "$XDG_CONFIG_HOME/opencode/agents/builder.md"
if bash "$REPO/config/opencode/scripts/install.sh" --verify > "$TMP/opencode-verify-differs.log" 2>&1; then
  fail 'opencode verify accepted a retargeted link'
fi
grep -q '^differs.*builder.md' "$TMP/opencode-verify-differs.log" || fail 'opencode verify did not report a differing link'
bash "$REPO/config/opencode/scripts/install.sh" --force > "$TMP/opencode-restore.log" 2>&1 \
  || { cat "$TMP/opencode-restore.log" >&2; fail 'opencode --force did not restore a retargeted link'; }
links_to "$XDG_CONFIG_HOME/opencode/agents/builder.md" "$REPO/config/opencode/agents/builder.md"
pass 'harness installers link everything, prune stale links, back up replaced files, protect local edits and verify'

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

t3_home="$TMP/t3-home"
export T3CODE_HOME="$t3_home"
export HOME="$TMP/t3-user-home"
export XDG_CONFIG_HOME="$TMP/t3-user-home/.config"
export XDG_STATE_HOME="$TMP/t3-user-home/.local/state"
mkdir -p "$HOME"
saved_path="$PATH"
export PATH="/usr/bin:/bin"

if bash "$REPO/config/t3code/scripts/install.sh" --verify > "$TMP/t3-verify-fresh.log" 2>&1; then
  fail 't3code verify accepted a fresh HOME'
fi
grep -q '^missing' "$TMP/t3-verify-fresh.log" || fail 't3code verify did not report missing targets'
[[ ! -e "$T3CODE_HOME" ]] || fail 't3code verify wrote the T3 home'
bash "$REPO/config/t3code/scripts/install.sh" > "$TMP/t3-1.log" 2>&1 \
  || { cat "$TMP/t3-1.log" >&2; fail 't3code installer'; }
links_to "$T3CODE_HOME/userdata/keybindings.json" "$REPO/config/t3code/keybindings.json"
for theme in "$REPO"/config/t3code/themes/*.json; do
  cmp -s "$theme" "$T3CODE_HOME/userdata/themes/$(basename "$theme")" \
    || fail "theme not copied: $(basename "$theme")"
done
bash "$REPO/config/t3code/scripts/install.sh" > "$TMP/t3-2.log" 2>&1 \
  || { cat "$TMP/t3-2.log" >&2; fail 't3code installer, second run'; }
grep -q '^copied\|^linked\|^backup' "$TMP/t3-2.log" && fail 'second t3code install was not a no-op'
bash "$REPO/config/t3code/scripts/install.sh" --verify > "$TMP/t3-verify-clean.log" 2>&1 \
  || { cat "$TMP/t3-verify-clean.log" >&2; fail 't3code verify after install'; }
grep -q '0 missing, 0 outdated, 0 different, 0 stale' "$TMP/t3-verify-clean.log" \
  || fail 't3code verify summary is not clean'

echo '# local theme edit' >> "$T3CODE_HOME/userdata/themes/matte-black.json"
if bash "$REPO/config/t3code/scripts/install.sh" --verify > "$TMP/t3-verify-differs.log" 2>&1; then
  fail 't3code verify accepted a local theme edit'
fi
grep -q '^differs.*matte-black.json' "$TMP/t3-verify-differs.log" || fail 't3code verify did not report a differing theme'
if bash "$REPO/config/t3code/scripts/install.sh" > "$TMP/t3-conflict.log" 2>&1; then
  fail 't3code installer overwrote a local theme edit'
fi
bash "$REPO/config/t3code/scripts/install.sh" --force > "$TMP/t3-force.log" 2>&1 \
  || { cat "$TMP/t3-force.log" >&2; fail 't3code --force'; }
grep -rqx '# local theme edit' "$XDG_STATE_HOME/t3code-dotfiles-backup" || fail 't3 theme edit not backed up'
bash "$REPO/config/t3code/scripts/install.sh" --verify > "$TMP/t3-verify-restored.log" 2>&1 \
  || { cat "$TMP/t3-verify-restored.log" >&2; fail 't3code verify after force'; }
pass 't3code installer links keybindings, copies themes, protects local edits and verifies'

export HOME="$TMP/dispatch-home" XDG_CONFIG_HOME="$TMP/dispatch-home/.config" XDG_STATE_HOME="$TMP/dispatch-home/.local/state"
export CLAUDE_CONFIG_DIR="$TMP/dispatch-home/.claude"
export T3CODE_HOME="$TMP/dispatch-t3"
mkdir -p "$HOME"

bash "$REPO/install.sh" --help > "$TMP/dispatch-help.log" 2>&1 || fail 'install.sh --help failed'
grep -q 'verify' "$TMP/dispatch-help.log" || fail 'install.sh help lacks verify'
bash "$REPO/install.sh" > "$TMP/dispatch-noargs.log" 2>&1 || fail 'install.sh without arguments failed'
grep -q 'Usage:' "$TMP/dispatch-noargs.log" || fail 'install.sh without arguments did not print usage'
if bash "$REPO/install.sh" nope > /dev/null 2>&1; then fail 'install.sh accepted an unknown command'; fi
if bash "$REPO/install.sh" verify --force > /dev/null 2>&1; then fail 'install.sh verify accepted --force'; fi

bash "$REPO/install.sh" all > "$TMP/dispatch-all.log" 2>&1 \
  || { cat "$TMP/dispatch-all.log" >&2; fail 'install.sh all failed'; }
bash "$REPO/install.sh" verify > "$TMP/dispatch-verify.log" 2>&1 \
  || { cat "$TMP/dispatch-verify.log" >&2; fail 'install.sh verify failed after all'; }
grep -q 'skipped git' "$TMP/dispatch-verify.log" || fail 'install.sh verify did not skip git'
rm "$HOME/.bashrc"
if bash "$REPO/install.sh" verify > "$TMP/dispatch-drift.log" 2>&1; then fail 'install.sh verify accepted drift'; fi
grep -q 'drift   shell' "$TMP/dispatch-drift.log" || fail 'install.sh verify summary did not report shell drift'
bash "$REPO/install.sh" shell > "$TMP/dispatch-shell.log" 2>&1 \
  || { cat "$TMP/dispatch-shell.log" >&2; fail 'install.sh shell failed'; }
bash "$REPO/install.sh" verify > "$TMP/dispatch-verify-2.log" 2>&1 \
  || { cat "$TMP/dispatch-verify-2.log" >&2; fail 'install.sh verify failed after shell repair'; }
export PATH="$saved_path"
pass 'top-level installer dispatches, aggregates verify and fails on drift'

shell_repo="$TMP/shell-repo"
mkdir -p "$shell_repo/scripts" "$shell_repo/config/shell/scripts"
cp "$REPO/scripts/install-lib.sh" "$shell_repo/scripts/"
cp "$REPO/config/shell/scripts/install.sh" "$shell_repo/config/shell/scripts/"
cp "$REPO/config/shell/bashrc" "$REPO/config/shell/profile" "$shell_repo/config/shell/"
shell_installer="$shell_repo/config/shell/scripts/install.sh"
export HOME="$TMP/shell-empty-home" XDG_STATE_HOME="$TMP/shell-empty-state"
bash "$shell_installer" > "$TMP/shell-empty.log" 2>&1
cmp -s "$HOME/.bashrc" "$shell_repo/config/shell/bashrc" || fail 'fresh bashrc not installed'
cmp -s "$HOME/.profile" "$shell_repo/config/shell/profile" || fail 'fresh profile not installed'
[[ ! -e "$XDG_STATE_HOME/shell-dotfiles-backup" ]] || fail 'fresh install created unnecessary backup'
export HOME="$TMP/shell-home" XDG_STATE_HOME="$TMP/shell-state"
mkdir -p "$HOME"
echo 'local bashrc' > "$HOME/.bashrc"
if bash "$shell_installer" > "$TMP/shell-conflict.log" 2>&1; then
  fail 'shell installer accepted an unmanaged local file'
fi
grep -qx 'local bashrc' "$HOME/.bashrc" || fail 'shell conflict changed bashrc'
[[ ! -e "$HOME/.profile" && ! -e "$XDG_STATE_HOME" ]] || fail 'shell conflict partially installed files'
bash "$shell_installer" --force > "$TMP/shell-1.log" 2>&1
grep -rqx 'local bashrc' "$XDG_STATE_HOME/shell-dotfiles-backup" || fail 'shell backup missing'
bash "$shell_installer" > "$TMP/shell-2.log" 2>&1
grep -q '^copied\|^backup' "$TMP/shell-2.log" && fail 'second shell install was not a no-op'
cmp -s "$HOME/.bashrc" "$shell_repo/config/shell/bashrc" || fail 'bashrc not installed'
cmp -s "$HOME/.profile" "$shell_repo/config/shell/profile" || fail 'profile not installed'
[[ ! -L "$HOME/.bashrc" && ! -L "$HOME/.profile" ]] || fail 'shell install copies, not links'

echo '# repo update' >> "$shell_repo/config/shell/bashrc"
bash "$shell_installer" > "$TMP/shell-update.log" 2>&1
cmp -s "$HOME/.bashrc" "$shell_repo/config/shell/bashrc" || fail 'managed bashrc not updated'
find "$XDG_STATE_HOME/shell-dotfiles-backup" -name .bashrc -exec cmp -s "$REPO/config/shell/bashrc" {} \; -print \
  | grep -q . || fail 'managed update not backed up'
echo '# another repo update' >> "$shell_repo/config/shell/bashrc"
echo '# local profile edit' >> "$HOME/.profile"
if bash "$shell_installer" > "$TMP/shell-edited.log" 2>&1; then
  fail 'shell installer overwrote a local edit'
fi
grep -qx '# local profile edit' "$HOME/.profile" || fail 'local edit lost'
grep -qx '# another repo update' "$HOME/.bashrc" && fail 'conflict allowed a partial update'
bash "$shell_installer" --force > "$TMP/shell-force.log" 2>&1
grep -rqx '# local profile edit' "$XDG_STATE_HOME/shell-dotfiles-backup" || fail 'local edit not backed up'

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

tmux_repo="$TMP/tmux-repo"
mkdir -p "$tmux_repo/scripts" "$tmux_repo/config/tmux/scripts"
cp "$REPO/scripts/install-lib.sh" "$tmux_repo/scripts/"
cp "$REPO/config/tmux/scripts/install.sh" "$tmux_repo/config/tmux/scripts/"
cp "$REPO/config/tmux/tmux.conf" "$tmux_repo/config/tmux/"
cp "$REPO/config/tmux/scripts/startup.sh" "$REPO/config/tmux/scripts/mksession.sh" \
  "$REPO/config/tmux/scripts/autostart.sh" "$tmux_repo/config/tmux/scripts/"
tmux_installer="$tmux_repo/config/tmux/scripts/install.sh"
export HOME="$TMP/tmux-home" XDG_STATE_HOME="$TMP/tmux-state"
bash "$tmux_installer" > "$TMP/tmux-fresh.log" 2>&1
cmp -s "$HOME/.config/tmux/tmux.conf" "$tmux_repo/config/tmux/tmux.conf" || fail 'fresh tmux.conf not installed'
cmp -s "$HOME/.config/tmux/scripts/startup.sh" "$tmux_repo/config/tmux/scripts/startup.sh" || fail 'fresh tmux startup not installed'
cmp -s "$HOME/.config/tmux/scripts/autostart.sh" "$tmux_repo/config/tmux/scripts/autostart.sh" || fail 'fresh tmux autostart not installed'
[[ -x "$HOME/.config/tmux/scripts/startup.sh" ]] || fail 'tmux startup permissions'
[[ -L "$HOME/.local/bin/mksession" ]] || fail 'mksession link missing'
[[ "$(readlink -f "$HOME/.local/bin/mksession")" == "$(readlink -f "$tmux_repo/config/tmux/scripts/mksession.sh")" ]] \
  || fail 'mksession link target'
[[ ! -e "$XDG_STATE_HOME/tmux-dotfiles-backup" ]] || fail 'fresh tmux install created unnecessary backup'
echo '# local edit' >> "$HOME/.config/tmux/tmux.conf"
if bash "$tmux_installer" > "$TMP/tmux-conflict.log" 2>&1; then
  fail 'tmux installer overwrote a local edit'
fi
grep -qx '# local edit' "$HOME/.config/tmux/tmux.conf" || fail 'tmux local edit lost'
bash "$tmux_installer" --force > "$TMP/tmux-force.log" 2>&1
grep -rqx '# local edit' "$XDG_STATE_HOME/tmux-dotfiles-backup" || fail 'tmux local edit not backed up'
bash "$tmux_installer" > "$TMP/tmux-2.log" 2>&1
grep -q '^copied\|^backup' "$TMP/tmux-2.log" && fail 'second tmux install was not a no-op'
rm "$HOME/.local/bin/mksession"
echo 'local link target' > "$HOME/.local/bin/mksession"
if bash "$tmux_installer" > "$TMP/tmux-link.log" 2>&1; then
  fail 'tmux installer accepted an unmanaged mksession file'
fi
grep -qx 'local link target' "$HOME/.local/bin/mksession" || fail 'tmux conflict changed mksession file'
bash "$tmux_installer" --force > "$TMP/tmux-link-force.log" 2>&1
grep -rqx 'local link target' "$XDG_STATE_HOME/tmux-dotfiles-backup" || fail 'mksession file not backed up'
[[ -L "$HOME/.local/bin/mksession" ]] || fail 'mksession not relinked after force'
rm "$HOME/.local/bin/mksession"
mkdir "$HOME/.local/bin/mksession"
if bash "$tmux_installer" --force > "$TMP/tmux-link-directory.log" 2>&1; then
  fail 'tmux installer replaced a mksession directory'
fi
[[ -d "$HOME/.local/bin/mksession" ]] || fail 'tmux installer changed a mksession directory'
pass 'tmux installer installs files and the mksession link, protects local edits and link conflicts, and is idempotent'
