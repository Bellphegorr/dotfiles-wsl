#!/usr/bin/env bash

# Sobe o servidor tmux em background e restaura o snapshot do
# tmux-resurrect, sem fazer attach. O terminal atual segue como shell
# normal (não vira cliente tmux).

BOOTSTRAP_SESSION="__bootstrap"
LOCKFILE="/tmp/tmux-startup.lock"
SNAPSHOT="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/last"
RESTORE_SCRIPT="$HOME/.config/tmux/plugins/tmux-resurrect/scripts/restore.sh"
RESURRECT_PLUGIN="$HOME/.config/tmux/plugins/tmux-resurrect/resurrect.tmux"

command -v tmux >/dev/null 2>&1 || exit 0

if [ ! -f "$RESTORE_SCRIPT" ]; then
    echo "tmux: tmux-resurrect não encontrado (abra o tmux e rode prefix + I)" >&2
    exit 1
fi

# Não enfileira bootstraps se outro terminal já estiver restaurando.
exec 9>"$LOCKFILE" || exit 1
if flock -n -E 75 9; then
    :
else
    status=$?
    [ "$status" -eq 75 ] && exit 0
    echo "tmux: falha ao obter lock (status $status)" >&2
    exit "$status"
fi

# Ignora bootstrap órfão deixado por uma execução anterior interrompida.
if tmux ls 2>/dev/null | grep -qv "^${BOOTSTRAP_SESSION}:"; then
    exit 0
fi

# No WSL com systemd, o login do console (getty) não recebe as variáveis
# de interop do Windows; reconstruímos o ambiente para o servidor tmux.
if [ -d /run/WSL ] && WSL_INTEROP="$(ls /run/WSL/*_interop 2>/dev/null | head -1)"; then
    export WSL_INTEROP
    WINPATH=""
    for attempt in 1 2 3; do
        if WINPATH="$(timeout --kill-after=1s 5s wsl.exe -e sh -c 'echo "$PATH"' 9>&-)"; then
            WINPATH="$(printf '%s' "$WINPATH" | tr -d '\r')"
            case "$WINPATH" in *"mnt/c"*) break ;; *) WINPATH="" ;; esac
        else
            status=$?
            echo "tmux: falha ao consultar PATH do WSL (tentativa $attempt, status $status)" >&2
            WINPATH=""
        fi
        [ "$attempt" -eq 3 ] || sleep 1
    done
    if [ -n "$WINPATH" ]; then
        case ":$PATH:" in
            *":$WINPATH:"*) ;;
            *) export PATH="$WINPATH:$PATH" ;;
        esac
    else
        echo "tmux: PATH do Windows indisponível; continuando com o PATH atual" >&2
    fi

    # WSLg: sem isso, panes do tmux (T3, herdr etc.) não têm display e
    # programas gráficos como o herdr-app não abrem janela.
    if [ -d /mnt/wslg ]; then
        if [ -S /tmp/.X11-unix/X0 ] && [ -z "${DISPLAY:-}" ]; then
            export DISPLAY=:0
        fi
        if [ -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/wayland-0" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
            export WAYLAND_DISPLAY=wayland-0
        fi
        if [ -S /mnt/wslg/PulseServer ] && [ -z "${PULSE_SERVER:-}" ]; then
            export PULSE_SERVER=unix:/mnt/wslg/PulseServer
        fi
    fi
fi

# Sobe o servidor com sessão bootstrap detached: o restore.sh precisa de
# um servidor rodando para executar comandos tmux. O fd do lock é fechado
# para o servidor não herdar o lock.
tmux kill-session -t "$BOOTSTRAP_SESSION" 2>/dev/null
tmux 9>&- new-session -d -s "$BOOTSTRAP_SESSION"

trap 'tmux kill-session -t "$BOOTSTRAP_SESSION" 2>/dev/null' EXIT

# O restore.sh usa $TMUX para achar o socket do servidor; como rodamos de
# fora do tmux, $TMUX está vazio e ele abriria um servidor fantasma.
SOCK="$(tmux display -p '#{socket_path}')"
SRV_PID="$(tmux display -p '#{pid}')"
export TMUX="${SOCK},${SRV_PID}"

# Se o TPM não carregou o resurrect (WSL, recarregamentos), registra as
# opções e bindings manualmente.
if ! tmux show-options -g @resurrect-restore-script-path >/dev/null 2>&1; then
    bash "$RESURRECT_PLUGIN"
fi

if [ ! -e "$SNAPSHOT" ]; then
    echo "tmux: nenhum snapshot para restaurar (normal antes do primeiro save)" >&2
    exit 0
fi

# Restaura o snapshot. O restore.sh chama switch-client para destacar
# janelas/sessões ativas; sem cliente isso gera "no current client" no
# stderr — ruído esperado que filtramos, mantendo erros reais visíveis.
"$RESTORE_SCRIPT" 2>&1 >/dev/null | grep -v '^no current client$' >&2

if ! tmux ls 2>/dev/null | grep -qv "^${BOOTSTRAP_SESSION}:"; then
    echo "tmux: restore não criou nenhuma sessão (verifique o snapshot)" >&2
    exit 1
fi
