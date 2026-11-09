#!/usr/bin/env bash
SESSION=${1:-projetos}
DIR=${2:-"$HOME/projetos"}

case "$DIR" in
    "~") DIR="$HOME" ;;
    "~/"*) DIR="$HOME/${DIR:2}" ;;
esac

if tmux has-session -t "$SESSION" 2>/dev/null; then
    if [ -n "$TMUX" ]; then
        tmux switch-client -t "$SESSION"
    else
        tmux attach -t "$SESSION"
    fi
    exit 0
fi

tmux new-session -d -s "$SESSION" -n agent
printf -v cd_command 'cd -- %q' "$DIR"
tmux send-keys -t "$SESSION:agent" "$cd_command" C-m
tmux new-window -t "$SESSION" -n terminal
tmux new-window -t "$SESSION" -n git

if [ -n "$TMUX" ]; then
    tmux switch-client -t "$SESSION"
else
    tmux attach -t "$SESSION"
fi
