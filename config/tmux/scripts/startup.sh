#!/usr/bin/env bash

# Se já existe servidor tmux, apenas attacha.
if tmux info >/dev/null 2>&1; then
    exec tmux attach
fi

# Cold start: cria sessão temporária detached para o restore.sh poder rodar,
# restaura todas as sessões do snapshot, remove a temporária e attacha.
tmux new-session -d -s __restore

# O restore.sh usa $TMUX para encontrar o socket do servidor.
# Como rodamos de fora do tmux, $TMUX está vazio e ele abre um server órfão.
# Descobrimos o socket/pid do servidor atual e preenchemos $TMUX.
SOCK="$(tmux display -p '#{socket_path}')"
SRV_PID="$(tmux display -p '#{pid}')"
export TMUX="${SOCK},${SRV_PID}"

sleep 1
/home/jose/.tmux/plugins/tmux-resurrect/scripts/restore.sh

unset TMUX
tmux kill-session -t __restore 2>/dev/null || true

if tmux has-session -t main 2>/dev/null; then
    exec tmux attach -t main
elif tmux ls >/dev/null 2>&1; then
    exec tmux attach
else
    exec tmux new-session -s main
fi
