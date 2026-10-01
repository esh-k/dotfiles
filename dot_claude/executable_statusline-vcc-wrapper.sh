#!/bin/bash
# Wrapper around `vcc statusline`: saves the statusline JSON payload (which
# carries cost.total_cost_usd) per tmux pane so ~/.tmux/claude-session-name.sh
# can show the same session cost in the pane header, then renders as before.
input=$(cat)
if [ -n "$TMUX_PANE" ]; then
    d="$HOME/.claude/state/pane-status"
    mkdir -p "$d"
    printf '%s' "$input" > "$d/$TMUX_PANE.$$" && mv -f "$d/$TMUX_PANE.$$" "$d/$TMUX_PANE.json"
fi
printf '%s' "$input" | exec vcc statusline "$@"
