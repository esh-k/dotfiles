# Headless layer: CLI tools, dotfiles, and everything the neovim config needs.

install_headless() {
    install_apt_packages
    install_chezmoi
    install_pyenv
    install_neovim_venv
    install_neovim
    install_tmux
    install_node
    install_go
    install_rust
    install_tree_sitter
    install_quarto
    install_utftex
    install_lean
    install_just
    install_bazel
    install_brew
    bootstrap_neovim
    bootstrap_tmux
}

install_apt_packages() {
    log "apt packages (latest git from git-core PPA, latest cmake from Kitware)"
    $SUDO apt-get update
    apt_install software-properties-common ca-certificates gnupg curl wget
    if ! grep -rqs git-core /etc/apt/sources.list.d/; then
        $SUDO add-apt-repository -y ppa:git-core/ppa
    fi
    if [[ ! -f /etc/apt/sources.list.d/kitware.list ]]; then
        curl -fsSL https://apt.kitware.com/keys/kitware-archive-latest.asc |
            gpg --dearmor | $SUDO tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null
        echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ $UBUNTU_CODENAME main" |
            $SUDO tee /etc/apt/sources.list.d/kitware.list >/dev/null
    fi
    $SUDO apt-get update
    $SUDO apt-get upgrade -y

    apt_install \
        git build-essential cmake pkg-config autoconf automake libtool gettext \
        unzip xz-utils file less locales sudo procps \
        ripgrep fd-find fzf jq imagemagick luarocks \
        `# pyenv python build deps` \
        libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
        tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
        `# tmux build deps` \
        libevent-dev libncurses-dev bison \
        `# rocq/coq for Coqtail` \
        coq \
        `# mason has no linux-arm64 clangd/clang-format, so use the distro ones` \
        clangd clang-format

    # Ubuntu ships fd as `fdfind`; telescope looks for `fd`.
    [[ -e /usr/local/bin/fd ]] || $SUDO ln -s "$(command -v fdfind)" /usr/local/bin/fd
    info "$(git --version)"
}

install_chezmoi() {
    log "chezmoi $CHEZMOI_VERSION + dotfiles"
    if ! has_version chezmoi "v$CHEZMOI_VERSION"; then
        local script
        script="$(fetch https://get.chezmoi.io)"
        $SUDO sh "$script" -b /usr/local/bin -t "v$CHEZMOI_VERSION"
    fi

    if [[ -d "$HOME/.local/share/chezmoi/.git" ]]; then
        # Files changed locally since the last apply (e.g. lazy-lock.json after a
        # plugin update) make chezmoi prompt; without a tty, keep them and move on.
        chezmoi update --apply --keep-going </dev/null ||
            warn "chezmoi skipped locally modified files; run 'chezmoi diff' to review"
    else
        # --force: replace Ubuntu's stock ~/.bashrc etc. without prompting.
        chezmoi init --apply --force "$DOTFILES_REPO"
    fi
}

install_pyenv() {
    log "pyenv $PYENV_VERSION + python $PYTHON_VERSION"
    export PYENV_ROOT="$HOME/.pyenv"
    if [[ ! -d "$PYENV_ROOT/.git" ]]; then
        git clone --depth 1 --branch "v$PYENV_VERSION" https://github.com/pyenv/pyenv.git "$PYENV_ROOT"
    elif ! "$PYENV_ROOT/bin/pyenv" --version | grep -qF "$PYENV_VERSION"; then
        git -C "$PYENV_ROOT" fetch --depth 1 origin tag "v$PYENV_VERSION"
        git -C "$PYENV_ROOT" checkout -q "v$PYENV_VERSION"
    fi
    export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

    pyenv install --skip-existing "$PYTHON_VERSION"
    pyenv global "$PYTHON_VERSION"
    info "$(python --version)"
}

# Python provider for neovim: molten, jupytext, Coqtail, render-markdown latex.
install_neovim_venv() {
    log "neovim python venv (~/.virtualenvs/neovim)"
    local venv="$HOME/.virtualenvs/neovim"
    [[ -x "$venv/bin/python" ]] || "$PYENV_ROOT/versions/$PYTHON_VERSION/bin/python" -m venv "$venv"
    "$venv/bin/pip" install --quiet --upgrade pip
    "$venv/bin/pip" install --quiet \
        pynvim jupyter_client cairosvg plotly kaleido pnglatex pyperclip pylatexenc \
        ipykernel jupyter-console jupytext
    "$venv/bin/python" -m ipykernel install --user --name=python3 --display-name="Python 3 (neovim)" >/dev/null
}

install_neovim() {
    log "neovim $NEOVIM_VERSION"
    if has_version nvim "NVIM v$NEOVIM_VERSION"; then
        info "already installed"
        return
    fi
    local tarball
    tarball="$(fetch "https://github.com/neovim/neovim/releases/download/v$NEOVIM_VERSION/nvim-linux-$ARCH_RAW.tar.gz")"
    $SUDO rm -rf /opt/nvim
    $SUDO mkdir -p /opt/nvim
    $SUDO tar -xzf "$tarball" -C /opt/nvim --strip-components=1
    $SUDO ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
}

install_tmux() {
    log "tmux $TMUX_VERSION (from source)"
    if has_version tmux "tmux $TMUX_VERSION" -V; then
        info "already installed"
        return
    fi
    local tarball dir
    tarball="$(fetch "https://github.com/tmux/tmux/releases/download/$TMUX_VERSION/tmux-$TMUX_VERSION.tar.gz")"
    dir="$(dirname "$tarball")"
    tar -xzf "$tarball" -C "$dir"
    (cd "$dir/tmux-$TMUX_VERSION" && ./configure --prefix=/usr/local >/dev/null && make -j"$(nproc)" >/dev/null)
    $SUDO make -C "$dir/tmux-$TMUX_VERSION" install >/dev/null
}

# Node: mason's npm-based servers (pyright, bash-language-server) + markdown-preview.
install_node() {
    log "node $NODE_VERSION"
    if has_version node "v$NODE_VERSION"; then
        info "already installed"
        return
    fi
    local tarball
    tarball="$(fetch "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH_X.tar.xz")"
    $SUDO rm -rf /opt/node
    $SUDO mkdir -p /opt/node
    $SUDO tar -xJf "$tarball" -C /opt/node --strip-components=1
    for bin in node npm npx corepack; do
        $SUDO ln -sf "/opt/node/bin/$bin" "/usr/local/bin/$bin"
    done
}

# Go: mason builds gopls with `go install`.
install_go() {
    log "go $GO_VERSION"
    if has_version go "go$GO_VERSION" version; then
        info "already installed"
        return
    fi
    local tarball
    tarball="$(fetch "https://go.dev/dl/go$GO_VERSION.linux-$ARCH_DEB.tar.gz")"
    $SUDO rm -rf /usr/local/go
    $SUDO tar -xzf "$tarball" -C /usr/local
    $SUDO ln -sf /usr/local/go/bin/go /usr/local/bin/go
    $SUDO ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
}

# Rust: the dotfiles' .bashrc sources ~/.cargo/env, and blink.cmp can build its fuzzy matcher.
install_rust() {
    log "rust (rustup, minimal profile)"
    if [[ -x "$HOME/.cargo/bin/rustup" ]]; then
        info "already installed"
        return
    fi
    curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal --no-modify-path
}

# tree-sitter CLI: required by nvim-treesitter's `main` branch to build parsers.
install_tree_sitter() {
    log "tree-sitter CLI $TREE_SITTER_VERSION"
    if has_version tree-sitter "$TREE_SITTER_VERSION"; then
        info "already installed"
        return
    fi
    local gz
    gz="$(fetch "https://github.com/tree-sitter/tree-sitter/releases/download/v$TREE_SITTER_VERSION/tree-sitter-linux-$ARCH_X.gz")"
    gunzip -c "$gz" | $SUDO tee /usr/local/bin/tree-sitter >/dev/null
    $SUDO chmod +x /usr/local/bin/tree-sitter
}

install_quarto() {
    log "quarto $QUARTO_VERSION"
    if has_version quarto "$QUARTO_VERSION"; then
        info "already installed"
        return
    fi
    local deb
    deb="$(fetch "https://github.com/quarto-dev/quarto-cli/releases/download/v$QUARTO_VERSION/quarto-$QUARTO_VERSION-linux-$ARCH_DEB.deb")"
    apt_install "$deb"
}

# utftex: render-markdown.nvim's LaTeX converter.
install_utftex() {
    log "utftex (libtexprintf)"
    if command -v utftex >/dev/null; then
        info "already installed"
        return
    fi
    local dir
    dir="$(mktemp -d)"
    git clone --depth 1 https://github.com/bartp5/libtexprintf.git "$dir/libtexprintf"
    (
        cd "$dir/libtexprintf"
        if [[ -x ./autogen.sh ]]; then ./autogen.sh; else autoreconf -fi; fi >/dev/null
        ./configure >/dev/null
        make -j"$(nproc)" >/dev/null
    )
    $SUDO make -C "$dir/libtexprintf" install >/dev/null
    $SUDO ldconfig
}

# Lean: lean.nvim uses the toolchain managed by elan (not mason).
install_lean() {
    log "lean (elan)"
    if [[ -x "$HOME/.elan/bin/elan" ]]; then
        info "already installed"
        return
    fi
    curl -fsSL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh |
        sh -s -- -y --default-toolchain stable --no-modify-path
}

install_just() {
    log "just $JUST_VERSION"
    if has_version just "just $JUST_VERSION"; then
        info "already installed"
        return
    fi
    local triple tarball
    case "$ARCH_DEB" in amd64) triple=x86_64 ;; arm64) triple=aarch64 ;; esac
    tarball="$(fetch "https://github.com/casey/just/releases/download/$JUST_VERSION/just-$JUST_VERSION-$triple-unknown-linux-musl.tar.gz")"
    $SUDO tar -xzf "$tarball" -C /usr/local/bin just
}

# bazelisk installed as `bazel`: each repo's .bazelversion picks the bazel release.
install_bazel() {
    log "bazelisk $BAZELISK_VERSION (as bazel)"
    if [[ -x /usr/local/bin/bazel ]] && grep -qF "v$BAZELISK_VERSION" /usr/local/share/bazelisk.version 2>/dev/null; then
        info "already installed"
        return
    fi
    $SUDO install -m 755 \
        "$(fetch "https://github.com/bazelbuild/bazelisk/releases/download/v$BAZELISK_VERSION/bazelisk-linux-$ARCH_DEB")" \
        /usr/local/bin/bazel
    echo "v$BAZELISK_VERSION" | $SUDO tee /usr/local/share/bazelisk.version >/dev/null
}

# Homebrew self-updates, so it isn't pinned. Installs to /home/linuxbrew/.linuxbrew.
install_brew() {
    log "homebrew"
    if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        info "already installed"
        return
    fi
    if [[ $EUID -eq 0 ]]; then
        warn "homebrew refuses to run as root, skipping"
        return
    fi
    NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

# Install lazy.nvim plugins and mason tools now rather than on first launch.
bootstrap_neovim() {
    log "neovim plugins + mason tools"
    export PATH="$HOME/.cargo/bin:$HOME/.elan/bin:$PATH"
    nvim --headless "+Lazy! restore" +qa 2>&1 | tail -n 5 || warn "lazy.nvim restore reported errors"
    nvim --headless "+MasonToolsInstallSync" +qa 2>&1 | tail -n 5 || true
    # The sync stops at the first failure (e.g. clangd has no linux-arm64 build),
    # so install whatever is still missing one package at a time.
    local tool
    for tool in $(nvim --headless "+luafile $SETUP_DIR/lib/mason_pending.lua" +qa 2>/dev/null | tr -d '\r'); do
        nvim --headless "+MasonInstall $tool" +qa >/dev/null 2>&1 || warn "mason could not install $tool"
    done
    nvim --headless "+UpdateRemotePlugins" +qa >/dev/null 2>&1 || warn "UpdateRemotePlugins failed"
}

bootstrap_tmux() {
    log "tmux plugins (tpm)"
    local tpm="$HOME/.tmux/plugins/tpm"
    [[ -d "$tpm" ]] || git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm"
    "$tpm/bin/install_plugins" >/dev/null || warn "tpm plugin install failed"
}
