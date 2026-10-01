#!/bin/bash
# Print "<session name> $<session cost>" for the Claude Code session in the given
# tmux pane id (e.g. %69).
# Name: Claude Code records each live session in ~/.claude/sessions/<pid>.json,
# including its tmux pane ("<sess>:@<win>.%<pane>"). If stale files share the
# pane id, the most recently updated one wins.
# Cost: cost.total_cost_usd from the statusline payload saved per pane by
# ~/.claude/statusline-vcc-wrapper.sh (same number the status line shows).
pane="$1"
[ -z "$pane" ] && exit 0
files=(~/.claude/sessions/*.json)
[ -e "${files[0]}" ] || exit 0
name=$(jq -rs --arg p ".$pane" '
  map(select((.tmux // "") | endswith($p)))
  | sort_by(.updatedAt) | last | .name // empty' "${files[@]}" 2>/dev/null)
[ -z "$name" ] && exit 0
cost=$(jq -r 'select(.cost.total_cost_usd != null) | .cost.total_cost_usd | "$" + (. * 100 | round / 100 | tostring)' \
    ~/.claude/state/pane-status/"$pane".json 2>/dev/null)
printf '%s%s' "$name" "${cost:+ $cost}"
