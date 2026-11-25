#!/usr/bin/env bash
# Auto-start tmux in interactive shells outside it; hooked from bashrc.
if command -v tmux >/dev/null 2>&1 && [ -z "$TMUX" ] && [ -n "$PS1" ]; then
    _tmux_state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/tmux"
    if (umask 077; mkdir -p "$_tmux_state_dir"); then
        (
            umask 077
            exec "$HOME/.config/tmux/scripts/startup.sh" </dev/null >/dev/null \
                2>>"$_tmux_state_dir/startup.log"
        ) &
    fi
    unset _tmux_state_dir
fi
