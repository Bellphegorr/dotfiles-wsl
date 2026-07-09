#!/usr/bin/env bash

# Se já existe servidor tmux, apenas attacha.
if tmux info >/dev/null 2>&1; then
    exec tmux attach
fi

RESTORE_SCRIPT="$HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh"
RESURRECT_PLUGIN="$HOME/.tmux/plugins/tmux-resurrect/resurrect.tmux"

if [ ! -f "$RESTORE_SCRIPT" ]; then
    echo "tmux-resurrect não encontrado em $RESTORE_SCRIPT" >&2
    echo "Abra o tmux e rode: prefix + I" >&2
    exec tmux new-session -s main
fi

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

# Attach: prioriza "main", senão qualquer sessão, senão cria main do zero.
if tmux has-session -t main 2>/dev/null; then
    exec tmux attach -t main
elif tmux ls >/dev/null 2>&1; then
    exec tmux attach
else
    exec tmux new-session -s main
fi
