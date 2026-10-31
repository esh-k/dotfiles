# Machine setup

Sets up an Ubuntu machine with these dotfiles and the tools they depend on.

```bash
curl -fsSL https://raw.githubusercontent.com/esh-k/dotfiles/main/setup/install.sh | bash
```

The headless layer always installs; you're asked whether to add the GUI layer.
Skip the prompt with `bash -s -- --headless` or `bash -s -- --gui`. Re-running is
safe and upgrades anything whose pinned version changed.

| Layer | Installs |
|---|---|
| headless | git (git-core PPA), build tools, cmake (Kitware), chezmoi + these dotfiles, pyenv + Python, neovim (+ plugins, mason tools, python venv), tmux (+ tpm plugins), node, go, rust, tree-sitter CLI, quarto, utftex, coq, lean, just, bazel (bazelisk), homebrew |
| GUI | Chrome (amd64 only), kitty, Ghostty, JetBrainsMono Nerd Font, LaTeX + zathura, clipboard tools |

Versions are pinned in [`versions.env`](versions.env).

## Layout

- `install.sh`: entry point; clones this repo to `~/.local/share/chezmoi` when piped from curl
- `lib/headless.sh`, `lib/gui.sh`: one function per tool
- `test/run.sh --headless|--gui`: install into a fresh Ubuntu container, then run `test/verify.sh`, which exercises each tool (`PLATFORM=linux/amd64` to emulate x86)

To test a branch before merging:

```bash
curl -fsSL https://raw.githubusercontent.com/ekanchv/dotfiles/<branch>/setup/install.sh | DOTFILES_REF=<branch> bash
```
