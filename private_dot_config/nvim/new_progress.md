# new_progress.md — replay status

The entire `nvim_test` config implementation had been deleted (only
`requirements.md` + `progress.md` survived; the git repo had **zero commits**, so
nothing was recoverable from history). I recreated every file from scratch based
on `progress.md`. This file records only what could **not** be completed or
verified this session — everything else below "Replayed & verified" is done.

## Replayed & verified (headless, `NVIM_APPNAME=nvim_test`)
- All 23 lua files recreated; every file parses; `Lazy! sync` clean (37 plugins).
- Mason auto-installed all tools incl. `codelldb`, `clangd`, `stylua`, `jupytext`.
- `clangd` LSP attaches to a C buffer (no errors).
- `conform` formats lua (`stylua`).
- Telescope `find_files` opens; Obsession round-trip writes a restorable `Session.vim`.
- Markdown with a fenced ```go block + `$...$` math parses cleanly — the
  treesitter-0.12 shim works; only the documented benign `E31: No such mapping`
  appears in `v:errmsg` (expected per progress.md, not a real error).

## Could NOT be completed / verified (need external toolchains or interactive run)

1. **DAP end-to-end debug of a C program** — config is in place (codelldb adapter,
   c/cpp/rust launch configs, full keymaps) but the breakpoint→inspect run was
   **not** re-verified this session. codelldb defaults to `runInTerminal`, which
   can't run under `--headless`; verify interactively, or add
   `terminal = "console"` to the launch config for a headless test (see the note
   in `lua/plugins/dap.lua`).

2. **Lean 4** — `lean.nvim` is configured, but the toolchain is **not installed**:
   `elan`/`lake`/`leanls` are absent on PATH. Install separately (NOT Mason):
   ```
   curl https://elan.lean-lang.org/elan-init.sh -sSf | sh
   elan default stable
   ```
   Then verify the infoview updates on a small `.lean` proof.

3. **VimTeX live PDF** — `vimtex` is configured for `latexmk` continuous mode +
   Skim, but **`latexmk` is not installed** (autostart safely no-ops without it).
   Install a TeX distro + Skim: `brew install --cask mactex skim` (or BasicTeX +
   `tlmgr install latexmk`). Then opening a `.tex` should auto-compile and live-update.

4. **Rocq/Coq** — `Coqtail` is configured and `rocq` exists via opam
   (`~/.opam/default/bin/rocq`), but `coqtop` is not on PATH and Coqtail needs the
   **python3 provider** (`pip install pynvim`). Couldn't verify `:CoqStart` /
   stepping this session. Ensure `coqtop`/`rocq` is reachable and pynvim is present
   in the python host, then step through a `.v` file.

5. **Inline images (Jupyter plots / markdown images via `image.nvim`)** — requires
   a graphics-capable terminal (Ghostty/kitty/WezTerm) **plus `imagemagick`**
   (`brew install imagemagick`); under tmux `set -g allow-passthrough on`. Headless
   it just warns "cannot query terminal size" (harmless). Verify interactively in
   Ghostty. NOTE: `molten-venv` already exists in `stdpath('data')` and survived the
   deletion (has jupyter/ipython/latex2text), so the molten/markdown-latex paths are valid.

## Reconstruction caveats (recreated from prose — may need a tweak once used live)
These work in principle but couldn't be exercised against real state headlessly:

- **`<leader>fp` search-history picker** (`lua/configs/search_history.lua`) — the
  `telescope-smart-history` sqlite schema isn't documented in progress.md, so the
  reader detects the query/picker column names at runtime (`query`/`cmd`/`prompt`
  and `picker`/`type`). If `<leader>fp` shows blank rows, adjust the column names
  in `read_rows()` to match the actual `history` table.

- **grug-far session restore** (`lua/configs/grug_far_session.lua`) — reads
  `instance.state.inputs` (search/replacement/paths/flags/filesFilter) via grug-far's
  internal API. If restore doesn't repopulate after a session reload, the field path
  to the live inputs is what to revisit.

- **`maplocalleader` is set to `<space>`** (same as leader) — inferred from the
  progress.md note "`<localleader>r` (= `<space>r`)". All `<localleader>` maps
  (grug-far/coq/lean/vimtex) are buffer-local so they don't clash globally, but if
  you intended a different localleader (e.g. `\`), change it in `init.lua`.
