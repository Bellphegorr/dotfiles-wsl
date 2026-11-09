#!/usr/bin/env bash
SESSION=${1:-projetos}
DIR=${2:-"$HOME/projetos"}

case "$DIR" in
    "~") DIR="$HOME" ;;
    "~/"*) DIR="$HOME/${DIR:2}" ;;
esac

if [ ! -d "$DIR" ]; then
    echo "mksession: diretório não encontrado: $DIR" >&2
    exit 1
fi

# Caminho absoluto, para o tmux não depender do cwd do servidor.
DIR=$(cd "$DIR" && pwd)

if tmux has-session -t "$SESSION" 2>/dev/null; then
    if [ -n "$TMUX" ]; then
        tmux switch-client -t "$SESSION"
    else
        tmux attach -t "$SESSION"
    fi
    exit 0
fi

tmux new-session -d -s "$SESSION" -n agent -c "$DIR"
tmux new-window -t "$SESSION" -n terminal -c "$DIR"
tmux new-window -t "$SESSION" -n git -c "$DIR"

if [ -n "$TMUX" ]; then
    tmux switch-client -t "$SESSION"
else
    tmux attach -t "$SESSION"
fi
