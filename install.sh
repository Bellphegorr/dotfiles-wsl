#!/usr/bin/env bash
# Thin dispatcher for the dotfiles installers. Each per-tool script remains the
# source of truth for what it installs; this only chooses, sequences and
# aggregates them.
set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
ALL=(shell tmux opencode claude copilot t3code)

usage() {
  cat <<'EOF'
Usage: bash install.sh <command> [--force]
       bash install.sh verify

Commands:
  shell      bashrc and profile
  tmux       tmux.conf, startup/autostart scripts and mksession
  opencode   opencode.jsonc, agents and shared skills
  claude     Claude Code agents and shared skills (honors CLAUDE_CONFIG_DIR)
  copilot    Copilot CLI agents and shared skills
  t3code     keybindings and themes
  git        configure the Windows credential manager (not in all)
  all        run shell, tmux, opencode, claude, copilot and t3code
  verify     report drift without writing; git is skipped

Options:
  --force    replace local edits after backing them up
  --help     show this help
EOF
}

script_for() {
  case "$1" in
    shell) echo "$REPO/config/shell/scripts/install.sh" ;;
    tmux) echo "$REPO/config/tmux/scripts/install.sh" ;;
    opencode) echo "$REPO/config/opencode/scripts/install.sh" ;;
    claude) echo "$REPO/config/claude/scripts/install.sh" ;;
    copilot) echo "$REPO/config/copilot/scripts/install.sh" ;;
    t3code) echo "$REPO/config/t3code/scripts/install.sh" ;;
    git) echo "$REPO/config/git/configure-gcm.sh" ;;
    *) return 1 ;;
  esac
}

install_one() { # name script [installer args...]
  local name="$1" script="$2"
  shift 2
  echo "==> $name"
  if ! bash "$script" "$@"; then
    echo "failed: $name" >&2
    exit 1
  fi
}

COMMAND="${1:-}"
if [[ -z "$COMMAND" ]]; then
  usage
  exit 0
fi
case "$COMMAND" in
  -h | --help)
    usage
    exit 0
    ;;
esac
shift || true

FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    -h | --help) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done

if [[ "$COMMAND" == verify && "$FORCE" == 1 ]]; then
  echo "error: --force does not apply to verify" >&2
  exit 1
fi

INSTALL_ARGS=()
[[ "$FORCE" == 1 ]] && INSTALL_ARGS+=(--force)

case "$COMMAND" in
  all)
    for name in "${ALL[@]}"; do
      install_one "$name" "$(script_for "$name")" "${INSTALL_ARGS[@]}"
    done
    ;;
  verify)
    failed=0
    results=()
    for name in "${ALL[@]}"; do
      echo "==> $name"
      if bash "$(script_for "$name")" --verify; then
        results+=("ok      $name")
      else
        results+=("drift   $name")
        failed=1
      fi
    done
    results+=("skipped git")
    echo
    echo "Verify summary:"
    printf '%s\n' "${results[@]}"
    exit "$failed"
    ;;
  shell | tmux | opencode | claude | copilot | t3code)
    install_one "$COMMAND" "$(script_for "$COMMAND")" "${INSTALL_ARGS[@]}"
    ;;
  git)
    [[ "$FORCE" == 1 ]] && echo "warning: --force is ignored for git" >&2
    install_one git "$(script_for git)"
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac
