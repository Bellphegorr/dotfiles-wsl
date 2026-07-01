#!/usr/bin/env bash

SESSION=main

if tmux has-session -t "$SESSION" 2>/dev/null; then
    exec tmux attach -t "$SESSION"
fi

tmux new-session -d -s "$SESSION" -n editor

tmux send-keys -t "$SESSION:editor" "cd ~/projetos" C-m

tmux new-window -t "$SESSION" -n terminal

tmux new-window -t "$SESSION" -n git

tmux new-window -t "$SESSION" -n scratch

exec tmux attach -t "$SESSION"
