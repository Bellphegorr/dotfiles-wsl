#!/usr/bin/env bash
# Auto-start tmux in interactive shells outside it; hooked from bashrc.
if command -v tmux >/dev/null && [ -z "$TMUX" ] && [ -n "$PS1" ]; then
    "$HOME/.config/tmux/scripts/startup.sh" >/dev/null &
fi
