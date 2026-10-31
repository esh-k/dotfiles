# Shared helpers. Sourced by install.sh.

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die() {
    printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
    exit 1
}

require_ubuntu() {
    [[ -r /etc/os-release ]] && . /etc/os-release
    [[ "${ID:-}" == ubuntu ]] || die "this script targets Ubuntu (found ${ID:-unknown})"
}

# Run as root without sudo (containers), otherwise cache sudo credentials up front.
init_sudo() {
    if [[ $EUID -eq 0 ]]; then
        SUDO=""
    else
        SUDO="sudo"
        sudo -v
        # Keep the sudo timestamp fresh during long builds (python, tmux).
        while true; do
            sudo -n true
            sleep 50
            kill -0 "$$" 2>/dev/null || exit
        done 2>/dev/null &
    fi
    export DEBIAN_FRONTEND=noninteractive
}

# Architecture names as used by the various release tarballs.
case "$(uname -m)" in
    x86_64) ARCH_DEB=amd64 ARCH_X=x64 ARCH_RAW=x86_64 ;;
    aarch64 | arm64) ARCH_DEB=arm64 ARCH_X=arm64 ARCH_RAW=arm64 ;;
    *) die "unsupported architecture: $(uname -m)" ;;
esac

apt_install() { $SUDO apt-get install -y --no-install-recommends "$@"; }

# True when `cmd` exists and its version output contains `want`.
has_version() {
    local cmd="$1" want="$2" flag="${3:---version}"
    command -v "$cmd" >/dev/null 2>&1 && "$cmd" "$flag" 2>&1 | grep -qF "$want"
}

# Download a URL into a fresh temp dir and echo the file path.
fetch() {
    local url="$1" dir
    dir="$(mktemp -d)"
    curl -fsSL --retry 3 -o "$dir/${url##*/}" "$url"
    echo "$dir/${url##*/}"
}
