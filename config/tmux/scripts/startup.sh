#!/usr/bin/env bash

LOCKDIR="/tmp/tmux-restore.lock"
LOCK_MAX_WAIT=60

# Espera o lock sumir. Se o dono do lock morreu ou o tempo esgotou,
# remove o lock preso (stale) e segue em frente, evitando travar o terminal.
wait_for_lock() {
    local waited=0
    while [ -d "$LOCKDIR" ]; do
        if [ -f "$LOCKDIR/pid" ] && ! kill -0 "$(cat "$LOCKDIR/pid" 2>/dev/null)" 2>/dev/null; then
            rm -rf "$LOCKDIR"
            return
        fi
        sleep 0.5
        waited=$((waited + 1))
        if [ "$waited" -ge "$LOCK_MAX_WAIT" ]; then
            echo "tmux: lock expirado, removendo $LOCKDIR" >&2
            rm -rf "$LOCKDIR"
            return
        fi
    done
}

# Se já existe servidor tmux, as sessões já estão restauradas (ou em
# andamento por outro processo). Não faz nada: o terminal segue normal.
if tmux info >/dev/null 2>&1; then
    exit 0
fi

RESTORE_SCRIPT="$HOME/.config/tmux/plugins/tmux-resurrect/scripts/restore.sh"
RESURRECT_PLUGIN="$HOME/.config/tmux/plugins/tmux-resurrect/resurrect.tmux"

if [ ! -f "$RESTORE_SCRIPT" ]; then
    echo "tmux-resurrect não encontrado em $RESTORE_SCRIPT" >&2
    echo "Abra o tmux e rode: prefix + I" >&2
    exec tmux new-session -d -s main
fi

# Adquire lock atômico. Se outra instância já estiver restaurando, aguarda.
if ! mkdir "$LOCKDIR" 2>/dev/null; then
    wait_for_lock
    exit 0
fi
echo $$ > "$LOCKDIR/pid"
trap 'rm -rf "$LOCKDIR"' EXIT

# Cold start: sobe servidor com sessão temporária detached.
# O restore.sh precisa de um servidor rodando para executar comandos tmux.
RESTORE_SESSION="__restore_$$"
tmux new-session -d -s "$RESTORE_SESSION"

# O restore.sh usa $TMUX para descobrir o socket do servidor.
# Como rodamos de fora do tmux, $TMUX está vazio e ele abriria um servidor
# fantasma. Preenchemos com socket/pid do servidor atual.
SOCK="$(tmux display -p '#{socket_path}')"
SRV_PID="$(tmux display -p '#{pid}')"
export TMUX="${SOCK},${SRV_PID}"

# Garante que o tmux-resurrect registre seus bindings e opções.
# Útil quando o TPM não carregou o plugin automaticamente (WSL, recarregamentos).
bash "$RESURRECT_PLUGIN"

# Espera o TPM carregar os plugins (máx 5s).
for _ in {1..10}; do
    if tmux show-options -g @resurrect-save-script-path >/dev/null 2>&1; then
        break
    fi
    sleep 0.5
done

# Restaura sessões salvas no snapshot.
"$RESTORE_SCRIPT"

unset TMUX
tmux kill-session -t "$RESTORE_SESSION" 2>/dev/null || true

# Sem attach: as sessões restauradas ficam vivas no servidor em background.
# Para entrar, rode `tmux attach` quando quiser.
if tmux has-session -t main 2>/dev/null; then
    true
elif ! tmux ls >/dev/null 2>&1; then
    tmux new-session -d -s main
fi
