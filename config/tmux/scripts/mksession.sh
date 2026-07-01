#!/usr/bin/env bash
SESSION=${1:-projetos}
DIR=${2:-~/projetos}

if tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux attach -t "$SESSION"
    exit 0
fi

tmux new-session -d -s "$SESSION" -n agent
tmux send-keys -t "$SESSION:agent" "cd $DIR" C-m
tmux new-window -t "$SESSION" -n terminal
tmux new-window -t "$SESSION" -n git

tmux attach -t "$SESSION"
