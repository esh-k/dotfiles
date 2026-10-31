#!/usr/bin/env bash

# Custom nvim restore strategy for tmux-resurrect.
#
# Goal (see ~/.tmux.conf):
#   - If nvim was launched WITH an explicit session file (`nvim -S <file>`),
#     relaunch with the SAME session file.
#   - If nvim was launched WITHOUT a session, restore from a per-directory
#     "custom" session file that the nvim config auto-maintains via vim-obsession
#     (see lua/autocmds.lua -> tmux_nvim_session). The path is derived from the
#     pane's directory and MUST match the nvim side.
#   - Otherwise fall back to ./Session.vim (obsession's default name) in the
#     pane dir if present, else plain nvim.
#
# tmux-resurrect calls this as:  nvim_nvimsession.sh "<full command>" "<dir>"

ORIGINAL_COMMAND="$1"
DIRECTORY="$2"

# Where nvim stores auto-created per-directory sessions. Keep in sync with the
# nvim autocmd (lua/autocmds.lua).
SESSION_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nvim/tmux-sessions"

# Encode an absolute directory path to a flat filename: every "/" -> "%".
# Must match the nvim side: dir:gsub("/", "%%").
custom_session_file() {
	echo "${SESSION_DIR}/$(echo "$DIRECTORY" | sed 's#/#%#g').vim"
}

main() {
	# 1. Launched with an explicit session file -> reuse the exact same file.
	if [[ "$ORIGINAL_COMMAND" =~ -S[[:space:]]+([^[:space:]]+) ]]; then
		echo "nvim -S ${BASH_REMATCH[1]}"
		return
	fi

	# 2. Per-directory custom auto-session (obsession-maintained) exists.
	local custom
	custom="$(custom_session_file)"
	if [ -e "$custom" ]; then
		echo "nvim -S $custom"
		return
	fi

	# 3. Obsession's default Session.vim in the pane's directory.
	if [ -e "${DIRECTORY}/Session.vim" ]; then
		echo "nvim -S"
		return
	fi

	# 4. Nothing to restore.
	echo "nvim"
}
main
