#!/usr/bin/env bash
# Machine setup for Ubuntu. Installs the headless layer by default and asks
# whether to add the GUI layer on top.
#
#   ./install.sh              # headless, prompt for GUI
#   ./install.sh --gui        # headless + GUI, no prompt
#   ./install.sh --headless   # headless only, no prompt
#
# Safe to re-run: every step skips work that is already done at the pinned version.
# Lives in the dotfiles repo under setup/ (excluded from chezmoi via .chezmoiignore).
set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/esh-k/dotfiles.git}"
DOTFILES_REF="${DOTFILES_REF:-main}"
SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"

# When run via `curl | bash` the sibling files aren't on disk, so clone the dotfiles
# repo straight into chezmoi's source dir and run the installer from there.
if [[ -z "$SETUP_DIR" || ! -f "$SETUP_DIR/lib/common.sh" ]]; then
    source_dir="$HOME/.local/share/chezmoi"
    if [[ -d "$source_dir/.git" ]]; then
        git -C "$source_dir" pull --ff-only
    else
        command -v git >/dev/null || { sudo apt-get update && sudo apt-get install -y git; }
        git clone --branch "$DOTFILES_REF" "$DOTFILES_REPO" "$source_dir"
    fi
    exec bash "$source_dir/setup/install.sh" "$@"
fi

source "$SETUP_DIR/versions.env"
source "$SETUP_DIR/lib/common.sh"
source "$SETUP_DIR/lib/headless.sh"
source "$SETUP_DIR/lib/gui.sh"

INSTALL_GUI=""
for arg in "$@"; do
    case "$arg" in
        --gui) INSTALL_GUI=yes ;;
        --headless) INSTALL_GUI=no ;;
        -h | --help)
            sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) die "unknown argument: $arg" ;;
    esac
done

if [[ -z "$INSTALL_GUI" ]]; then
    INSTALL_GUI=no
    # Read from the terminal so the prompt works under `curl | bash` too.
    if [[ -r /dev/tty ]]; then
        read -r -p "Install GUI apps (Chrome, kitty, fonts, LaTeX viewer)? [y/N] " reply </dev/tty || true
        [[ "$reply" =~ ^[Yy] ]] && INSTALL_GUI=yes
    fi
fi

require_ubuntu
init_sudo

install_headless
[[ "$INSTALL_GUI" == yes ]] && install_gui

log "Done. Open a new shell (or run: exec bash -l) to pick up PATH changes."
