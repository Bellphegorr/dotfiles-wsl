#!/usr/bin/env bash
SESSION=${1:-projetos}
DIR=${2:-~/projetos}

if tmux has-session -t "$SESSION" 2>/dev/null; then
    if [ -n "$TMUX" ]; then
        tmux switch-client -t "$SESSION"
    else
        tmux attach -t "$SESSION"
    fi
    exit 0
fi

tmux new-session -d -s "$SESSION" -n agent
tmux send-keys -t "$SESSION:agent" "cd $DIR" C-m
tmux new-window -t "$SESSION" -n terminal
tmux new-window -t "$SESSION" -n git

if [ -n "$TMUX" ]; then
    tmux switch-client -t "$SESSION"
else
    tmux attach -t "$SESSION"
fi
