#!/usr/bin/env bash

SESSION=main

if tmux has-session -t "$SESSION" 2>/dev/null; then
    exec tmux attach -t "$SESSION"
fi

tmux new-session -d -s "$SESSION" -n agent

tmux send-keys -t "$SESSION:agent" "cd ~/projetos" C-m

tmux new-window -t "$SESSION" -n terminal

tmux new-window -t "$SESSION" -n git

exec tmux attach -t "$SESSION"
