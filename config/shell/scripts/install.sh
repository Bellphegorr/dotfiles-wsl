#!/usr/bin/env bash
# Installs bashrc and profile into $HOME with conflict detection and backups.
set -euo pipefail

usage() {
  echo "Usage: bash config/shell/scripts/install.sh [--force|--verify]"
  echo "Copies bashrc and profile; --force backs up and replaces local changes."
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
SHELL_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
REPO="$(cd "$SHELL_DIR/../.." && pwd)"
# shellcheck source=../../../scripts/install-lib.sh
source "$REPO/scripts/install-lib.sh"

bash -n "$SHELL_DIR/bashrc"
bash -n "$SHELL_DIR/profile"

install_begin shell "$FORCE" "$VERIFY"
install_file "$SHELL_DIR/bashrc" ".bashrc" 644
install_file "$SHELL_DIR/profile" ".profile" 644
install_run

if [[ "$VERIFY" == 0 ]]; then
  echo
  echo "Done. Open a new shell to load bashrc and profile."
fi
