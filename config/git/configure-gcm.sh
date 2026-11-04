#!/usr/bin/env bash

set -euo pipefail

case "${1:-}" in
    -h|--help) echo "Uso: configure-gcm.sh [--check]"; exit 0 ;;
    --check) check_only=true ;;
    "") check_only=false ;;
    *) echo "Uso: configure-gcm.sh [--check]" >&2; exit 2 ;;
esac

if [[ -z "${WSL_DISTRO_NAME:-}" ]] &&
    ! grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
    echo "Este script é específico para WSL." >&2
    exit 0
fi

gcm="${GCM_PATH:-}"
[[ -n "$gcm" ]] || gcm="$(command -v git-credential-manager.exe 2>/dev/null || true)"
if [[ -z "$gcm" ]]; then
    for candidate in \
        "/mnt/c/Program Files/Git/ucrt64/bin/git-credential-manager.exe" \
        "/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe"; do
        [[ -x "$candidate" ]] && { gcm="$candidate"; break; }
    done
fi

if [[ -z "$gcm" || ! -x "$gcm" ]]; then
    echo "GCM não encontrado; defina GCM_PATH." >&2
    exit 1
fi

helper="!\"${gcm}\""

if $check_only; then
    current_helper="$(git config --global --get credential.helper 2>/dev/null || true)"
    current_provider="$(git config --global --get credential.https://github.com.provider 2>/dev/null || true)"
    printf 'helper:   %s\nprovider: %s\n' \
        "${current_helper:-(nenhum)}" "${current_provider:-(nenhum)}"

    if [[ "$current_helper" == "$helper" && "$current_provider" == "github" ]]; then
        echo "Configuração OK."
        exit 0
    fi

    echo "Configuração incompleta."
    exit 1
fi

git config --global --replace-all credential.helper "$helper"
git config --global --replace-all credential.https://github.com.provider github
echo "Configuração aplicada: $helper"
