#!/usr/bin/env bash
# Installs tmux.conf, startup.sh and the mksession link with conflict
# detection and backups.
set -euo pipefail

usage() {
  echo "Usage: bash config/tmux/scripts/install.sh [--force|--verify]"
  echo "Copies tmux.conf, startup.sh and the mksession link; --force backs up and replaces local changes."
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
TMUX_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
REPO="$(cd "$TMUX_DIR/../.." && pwd)"
# shellcheck source=../../../scripts/install-lib.sh
source "$REPO/scripts/install-lib.sh"

bash -n "$TMUX_DIR/scripts/startup.sh"
bash -n "$TMUX_DIR/scripts/mksession.sh"
bash -n "$TMUX_DIR/scripts/autostart.sh"

install_begin tmux "$FORCE" "$VERIFY"
install_file "$TMUX_DIR/tmux.conf" ".config/tmux/tmux.conf" 644
install_file "$TMUX_DIR/scripts/startup.sh" ".config/tmux/scripts/startup.sh" 755
install_file "$TMUX_DIR/scripts/autostart.sh" ".config/tmux/scripts/autostart.sh" 644
install_link "$TMUX_DIR/scripts/mksession.sh" ".local/bin/mksession"
install_run

if [[ "$VERIFY" == 0 ]]; then
  echo
  echo "Done. Reload tmux with: tmux source-file \"\$HOME/.config/tmux/tmux.conf\""
fi
