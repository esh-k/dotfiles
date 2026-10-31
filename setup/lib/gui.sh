# GUI layer: desktop apps on top of the headless layer.

install_gui() {
    install_gui_packages
    install_chrome
    install_kitty
    install_ghostty
    install_nerd_font
}

# Ghostty has no official Ubuntu package; use the community-built debs.
install_ghostty() {
    log "ghostty $GHOSTTY_VERSION"
    if has_version ghostty "Ghostty $GHOSTTY_VERSION"; then
        info "already installed"
        return
    fi
    local deb_version="${GHOSTTY_DEB_TAG/-ppa/.ppa}"
    apt_install "$(fetch "https://github.com/mkasberg/ghostty-ubuntu/releases/download/$GHOSTTY_DEB_TAG/ghostty_${deb_version}_${ARCH_DEB}_${VERSION_ID}.deb")" ||
        warn "no ghostty $GHOSTTY_DEB_TAG deb for Ubuntu $VERSION_ID/$ARCH_DEB, skipping"
}

# Clipboard for neovim, a LaTeX toolchain + PDF viewer for vimtex, and the X/GL
# libraries kitty loads at runtime (missing from minimal Ubuntu images).
install_gui_packages() {
    log "GUI packages (clipboard, LaTeX, zathura, kitty runtime libs)"
    apt_install xclip wl-clipboard latexmk texlive-latex-extra zathura \
        libxcb-xkb1 libxkbcommon-x11-0 libegl1 libgl1 fontconfig
}

install_chrome() {
    log "google chrome"
    if command -v google-chrome >/dev/null; then
        info "already installed"
        return
    fi
    if [[ "$ARCH_DEB" != amd64 ]]; then
        warn "chrome has no linux build for $ARCH_DEB, skipping"
        return
    fi
    # The package adds Google's apt repo, so `apt upgrade` keeps it current.
    apt_install "$(fetch https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb)"
}

install_kitty() {
    log "kitty $KITTY_VERSION"
    local app="$HOME/.local/kitty.app"
    if [[ -x "$app/bin/kitty" ]] && "$app/bin/kitty" --version | grep -qF "$KITTY_VERSION"; then
        info "already installed"
        return
    fi
    curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh |
        sh /dev/stdin installer="version-$KITTY_VERSION" launch=n

    mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"
    ln -sf "$app/bin/kitty" "$app/bin/kitten" "$HOME/.local/bin/"
    cp "$app"/share/applications/kitty*.desktop "$HOME/.local/share/applications/"
    sed -i "s|Icon=kitty|Icon=$app/share/icons/hicolor/256x256/apps/kitty.png|g; \
            s|Exec=kitty|Exec=$app/bin/kitty|g" \
        "$HOME"/.local/share/applications/kitty*.desktop
    $SUDO update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$app/bin/kitty" 50
}

# blink.cmp and the statusline expect a Nerd Font.
install_nerd_font() {
    log "$NERD_FONT Nerd Font"
    local dir="$HOME/.local/share/fonts/$NERD_FONT"
    if [[ -d "$dir" ]]; then
        info "already installed"
        return
    fi
    mkdir -p "$dir"
    tar -xJf "$(fetch "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$NERD_FONT.tar.xz")" -C "$dir"
    fc-cache -f "$dir" >/dev/null
}
