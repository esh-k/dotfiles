# nvim_test — progress & notes

Standalone Neovim config (no NvChad / starter framework). Structure mirrors the
old `~/.config/nvim` layout: `options` / `mappings` / `autocmds` + `lua/plugins/*`
+ `lua/configs/*`. Run with: `NVIM_APPNAME=nvim_test nvim`.

## Layout
```
init.lua                  leader, lazy bootstrap, load order
lua/options.lua           editor opts, diagnostics, sessionoptions
lua/mappings.lua          general/tmux/buffer/session/format keys
lua/autocmds.lua          yank highlight, trim whitespace, q-to-close
lua/configs/lazy.lua      lazy.nvim settings (imports lua/plugins)
lua/plugins/init.lua      theme, tmux-nav, obsession, which-key, lualine, gitsigns, treesitter, trouble
lua/plugins/telescope.lua finder + marks + search/command history
lua/plugins/lsp.lua       mason, mason-tool-installer, blink.cmp, lspconfig, conform
lua/plugins/dap.lua       nvim-dap + dap-ui + virtual-text + codelldb
lua/plugins/bufferline.lua tabs for open files in the top bar
lua/plugins/grug-far.lua  multi-file search & replace (+ session persist)
lua/plugins/jupyter.lua   jupytext + molten + image.nvim (notebooks)
lua/plugins/lean.lua      lean.nvim (Lean 4)
lua/plugins/coq.lua       Coqtail (Rocq/Coq)
lua/configs/lspconfig.lua native vim.lsp.config/enable, LspAttach keymaps
lua/configs/conform.lua   formatters + Format{Toggle,Enable,Disable}
lua/configs/molten.lua    run-cell / run-all helpers for molten
```

## Requirements coverage
- **Sessions**: `tpope/vim-obsession`. `<leader>so` toggles; `:Obsession` writes
  `Session.vim`; restore with `nvim -S Session.vim`. `sessionoptions` tuned in options.lua.
- **Package manager**: `lazy.nvim` (auto-bootstraps on first launch).
- **Fuzzy finder**: Telescope (`<leader>ff/fb/fo/fr`, `<leader>/`). fzf-native sorter.
  `path_display = { "smart" }` shortens the base-directory prefix in results.
  - **Restores last input**: `<leader>fg` (grep) and `<leader>ff` (files) reopen
    pre-filled with the last prompt you typed — even if you never submitted it
    (smart_history only records executed searches). Implemented in
    `lua/configs/telescope_persist.lua`: an `on_lines` watcher on the prompt buffer
    continuously stores the prompt per picker title (mode-independent; TextChangedI
    is unreliable), and the keymaps pass it back as `default_text`.
  - **Live grep w/ include/exclude**: `<leader>fg` uses `telescope-live-grep-args`.
    IMPORTANT: `auto_quoting` is on, so the search term must be QUOTED before you
    add ripgrep flags. Easiest: type the term, press `<C-g>` (quotes it + appends
    ` --iglob `), then type a glob. For excludes, `<M-g>` appends ` --iglob !` so
    you just type the pattern to exclude. Both use
    `configs.lga_quote.quote_or_append`: if the term is already quoted they only
    append the flag (no quote nesting), so `<C-g>`/`<M-g>` chain on one line.
    Examples of the resulting prompt:
    - include only lua:  `"foo" --iglob *.lua`   (via `<C-g>`)
    - exclude tests:     `"foo" --iglob !**/test/**`   (via `<M-g>`)
    - exclude a dir:     `"foo" --iglob !build/**`   (via `<M-g>`)
    - both at once:      `"foo" --iglob *.lua --iglob !skip/**`   (`<C-g>` then `<M-g>`)
    `<C-y>` switches to a fuzzy refine over the current results. (This is the
    telescope *core* action `actions.to_fuzzy_refine`, NOT an lga action — the
    installed lga only exports `quote_prompt`, so `lga_actions.to_fuzzy_refine`
    was nil and the old `<C-space>` binding silently did nothing.)
    (Typing `foo -g *.lua` WITHOUT quoting the term searches the literal string and
    returns nothing — that was the earlier confusion.)
  - Marks viewer: `<leader>fm` (`Telescope marks`).
  - **Search history** (`telescope-smart-history` + `sqlite.lua`, DB at
    `stdpath('data')/telescope_history.sqlite3`):
    - In any picker prompt: `<C-Up>`/`<C-Down>` cycle previous prompts (works in the
      current session too).
    - `<leader>fp`: a browsable/fuzzy-searchable window of **all** past Telescope
      searches (grep, find files, buffers, help, oldfiles, keymaps, ...). Each row
      shows a type tag + the query; `<CR>` re-runs it in the matching picker
      (grep->live_grep_args, files->find_files, etc.). Implemented in
      `lua/configs/search_history.lua` (smart_history ships only a backend, no picker).
      Fuzzy-filter by type too, e.g. type "files" or "grep" to narrow.
      NOTE: smart_history holds its sqlite connection open, so a search made in the
      *current* session shows up in `<leader>fp` only after a restart; use
      `<C-Up>`/`<C-Down>` to recall same-session searches.
  - **Scrolling in any picker**: `<C-d>`/`<C-u>` scroll the preview (telescope
    defaults); `<M-d>`/`<M-u>` page-scroll the results list (added in defaults
    mappings, insert + normal).
  - `/`-search history: `<leader>sh`; `:`-command history: `<leader>sc`.
- **Tmux nav**: `vim-tmux-navigator`, `<C-h/j/k/l>` across vim splits + tmux panes.
- **LSP**: native `vim.lsp.enable` — lua_ls, clangd, gopls, pyright, bashls, jq_ls.
  Keys on attach: `gd gD gi gr K <leader>cr <leader>ca [d ]d`.
- **Debugger**: nvim-dap + dap-ui + codelldb. Full keys: `F5` continue, `F10/F11/F12`
  step over/into/out, `<leader>db` breakpoint, `<leader>du` UI, `<leader>de` eval, etc.
- **Mason**: `mason-tool-installer` auto-installs servers/formatters/codelldb on start.
- **Formatter**: `conform.nvim`, format-on-save toggleable per session.
  `<C-M-f>` / `<leader>cf` format; `<leader>uf` or `:FormatToggle` toggles (`:FormatDisable!` = buffer-only).
- **Cheat sheet / hints**: `which-key.nvim`. Popup hints for multi-key chords; full
  cheat sheet via `<leader>?`.
- **Multi search & replace (single buffer)**: `grug-far.nvim`. `<leader>sr` opens a
  single editable buffer for project-wide find/replace (type search + replacement,
  see all matches, apply everywhere). `<leader>sw` prefills the word under cursor;
  visual `<leader>sr` replaces within the selection. Inside the buffer:
  `<localleader>r` (= `<space>r`) applies the replace; `<localleader>s` syncs edits
  back. Backed by ripgrep.
  - **History**: persistent by default (grug-far auto-saves to
    `stdpath('state')/grug-far` on replace/sync/buffer-delete). Browse with
    `<localleader>t`, pick an entry with `<CR>` (config makes this explicit in opts).
  - **Session (Obsession)**: an open grug-far search is restored on session reload.
    `lua/configs/grug_far_session.lua` serializes the live inputs (search/replacement/
    paths/flags/filesFilter) into the `GrugFarSession` global (saved via
    `sessionoptions+=globals`) and reopens grug-far on `SessionLoadPost`. Registered
    at startup via the plugin's `init`. Closing the search clears the stored state.
- **Python/Jupyter notebooks** (`lua/plugins/jupyter.lua`): `jupytext.nvim` edits
  `.ipynb` as a percent-script (cells = `# %%`); `molten-nvim` runs cells against a
  Jupyter kernel with inline output; `image.nvim` renders plots inline.
  Keys: `<leader>mi` init kernel — detects the project's Python (activated
  `$VIRTUAL_ENV`/`$CONDA_PREFIX`, else a `.venv`/`venv`/`env` dir found by walking up
  from the file, else pyenv/PATH `python3`), resolves it to its real interpreter,
  **auto-registers a kernelspec for it if none exists**, and starts that kernel.
  Needs `ipykernel` in that env (it tells you the exact pip command if missing).
  `<leader>mp` forces molten's manual picker. (see `configs/molten.lua:init_kernel`)
  Cell navigation: `]]`/`[[` jump to the next/previous `# %%` cell — buffer-local in
  python/markdown buffers that actually contain markers (plain .py keeps its defaults).
  `<leader>mr` run cell, `<leader>mR` run cell
  & advance, `<leader>ma` run all cells, `<leader>ms`/`<leader>mh` show/hide output,
  `<leader>me` (visual) run selection, `<leader>mx` interrupt. Cell helpers in
  `lua/configs/molten.lua`.
  BACKENDS (installed):
    * jupytext CLI — via Mason (`jupytext` in mason-tool-installer ensure_installed).
    * molten deps (pynvim/jupyter_client/ipykernel) — NOT Mason-able (libraries, not
      executables). Live in `stdpath('data')/molten-venv`; init.lua sets
      `g:python3_host_prog` to it. A `nvim_test` ipykernel spec is registered.
      `:UpdateRemotePlugins` has been run (rplugin manifest generated).
    * Inline images (TODO by user): graphics terminal (kitty/WezTerm/Ghostty) +
      `brew install imagemagick`; under tmux `set -g allow-passthrough on`.
    VERIFIED end-to-end: opening .ipynb converts to percent script; `MoltenInit
    nvim_test` starts the kernel; running a cell executes (kernel stays alive).
    NOTE: `MoltenEvaluateRange` is a vim *function*, not a command — molten.lua
    calls it via `vim.fn.MoltenEvaluateRange(start, end)`.
- **Lean 4** (`lua/plugins/lean.lua`): `lean.nvim` + `leanls`, infoview with live goal
  state, clickable goals/diagnostics, unicode abbreviations (`\to`→`→`), completion via
  blink (inherited from the global `vim.lsp.config("*")`). Configured via
  `vim.g.lean_config` (setup() is deprecated). Default `<LocalLeader>` proof/infoview
  mappings enabled.
  BACKEND: toolchain via elan (NOT Mason):
    `curl https://elan.lean-lang.org/elan-init.sh -sSf | sh` then `elan default stable`.
- **Rocq/Coq** (`lua/plugins/coq.lua`): `whonore/Coqtail`, Proof-General style, with
  goals + info panels. `.v` is mapped to filetype `coq` (so the lazy `ft` trigger fires).
  Keys (buffer-local, normal): `<localleader>cc` start, `<localleader>cq` stop,
  `<localleader>j` step forward, `<localleader>k` step back, `<localleader>l` run to
  cursor, `<localleader>cg` go to goal.
  BACKEND: `brew install coq` (or `opam install coq`) + `pip install pynvim`
  (Coqtail needs the python3 provider; without it its commands don't register).
- **Markdown + LaTeX rendering** (`lua/plugins/markdown.lua`): `render-markdown.nvim`
  renders headings/code/tables/lists in-buffer (works in Ghostty & any terminal) and
  converts `$...$`/`$$...$$` math to Unicode via pylatexenc's `latex2text` (installed
  in the molten venv; render-markdown's `latex.converter` points at its absolute path).
  `<leader>um` toggles rendering. For fully graphical KaTeX equations: `<leader>up`
  (`markdown-preview.nvim`, browser). Embedded image files render inline in Ghostty via
  image.nvim's markdown integration. Treesitter parsers: markdown, markdown_inline,
  latex, html, yaml (render-markdown health all green; converter detected).
  NOTE: opening a markdown buffer leaves a benign `E31: No such mapping` in `v:errmsg`
  — it's the stock `ftplugin/markdown.lua` `silent!` unmap cleanup re-running when
  lazy.nvim ft-loads render-markdown (it re-fires FileType). Fully suppressed; `[[`/`]]`
  header-nav still works; not a real error.
- **LaTeX editing + live PDF** (`lua/plugins/vimtex.lua`): VimTeX with `latexmk`
  continuous mode — opening a `.tex` auto-starts compilation (guarded on `latexmk`
  being installed), so every save recompiles and the viewer updates live. Viewer:
  Skim (macOS, SyncTeX). Default `<localleader>l…` maps (`ll` toggle compile, `lv`
  view, `lc` clean, etc.). VimTeX owns `.tex` highlighting/conceal (treesitter's
  latex highlighter is disabled for tex in plugins/init.lua).
  BACKEND: a TeX distro with `latexmk` (MacTeX/BasicTeX) + Skim
  (`brew install --cask skim`). Verified: VimTeX loads, `:VimtexCompile`/`:VimtexView`
  registered, continuous=1, autostart safely no-ops without latexmk.
  NOTE: opening a `.tex` leaves a benign silent `E128` in `v:errmsg` (VimTeX
  internal; not echoed, commands work) — same class as the markdown `E31`.
- **Mermaid / graphical markdown**: rendered via the browser preview
  (`markdown-preview.nvim`, `<leader>up`) which bundles mermaid + KaTeX + images.
  There is no standard inline-terminal mermaid renderer; in-buffer you get
  image.nvim for images and render-markdown for unicode LaTeX.
- **Treesitter 0.12 compat shim** (`lua/configs/treesitter_fix.lua`): nvim-treesitter's
  frozen `master` branch ships query directives that assume `match[id]` is a single
  TSNode, but Neovim 0.12 passes an array — this crashed injection parsing and flooded
  markdown files containing fenced code blocks with `treesitter.lua: attempt to call
  method 'range' (a nil value)`, making them uneditable. The shim re-registers the
  affected directives (`set-lang-from-info-string!`, `set-lang-from-mimetype!`,
  `downcase!`) with array-safe handlers, applied right after the treesitter setup.
  Verified: a markdown file with a ```go fence now parses + highlights cleanly.
- **Tabs (top bar)**: `bufferline.nvim` (catppuccin theme via
  `catppuccin.special.bufferline.get_theme()`), `showtabline=2`, offset for NvimTree.
  `]b`/`[b` cycle tabs (BufferLineCycleNext/Prev); `<Tab>` is left unmapped so it
  keeps acting as `<C-i>`/jump-forward. `<leader>x` closes a buffer.
- **Comment toggle**: `<leader>/` toggles comments using built-in `gc`/`gcc` (normal:
  line, visual: selection). (Telescope's buffer fuzzy-find moved to `<leader>fz`.)
- **Save**: `<C-s>` writes the buffer in normal/insert/visual mode.
- **Theme**: catppuccin (mocha) with transparency, matching old `chadrc`.
  lualine theme is `catppuccin-mocha` (catppuccin has no plain `catppuccin` theme).
- **File tree**: `nvim-tree` (`<C-n>` toggle, `<leader>e` focus). Long names that
  overflow the tree width can be scrolled to horizontally — inside the tree:
  `l` scrolls right half a width, `h` scrolls left, `<End>`/`<Home>` jump to the end/
  start of the name. (`h`/`l` are unused by nvim-tree defaults; arrows/<C-arrows>
  were avoided since terminals/tmux often intercept them.) Tree window uses
  `nowrap` + `sidescrolloff=0` + `virtualedit=all`, global `sidescroll=1`.
  - `virtualedit=all` is REQUIRED: without it, zl/zh refuse to scroll while the
    cursor is on a short entry (Vim keeps the cursor on screen). Set via
    `vim.schedule` in on_attach because nvim-tree overwrites window opts post-attach.
  - Do NOT disable `netrwPlugin` in `configs/lazy.lua`: nvim-tree hijacks netrw's
    FileExplorer autocmd and throws E216 into v:errmsg if netrw never loaded.

## Verification (all headless via `NVIM_APPNAME=nvim_test`)
- Plugins sync clean; Mason installed all 12 tools incl. codelldb.
- Clean startup, no errors when opening a C file.
- `clangd` LSP attaches to a C buffer.
- conform formats lua (stylua) correctly.
- **DAP debugged a sample C program**: breakpoint hit at line 4, locals read
  `a=7, b=35, sum=0`, session terminated cleanly.
- Obsession round-trip creates a restorable `Session.vim`.

## Notes / gotchas
- **codelldb + headless**: codelldb defaults to launching the debuggee via
  `runInTerminal` (integrated terminal), which can't run under `--headless`.
  This is normal and works in interactive Neovim. For headless DAP testing only,
  add `terminal = "console"` to the launch config. The shipped config keeps the
  default (integrated terminal) for normal interactive use.
- Native `vim.lsp.config/enable` (Neovim 0.11+) is used instead of the old
  `require('lspconfig').xxx.setup{}`; server names follow nvim-lspconfig's `lsp/` dir.
- Completion is `blink.cmp` (not nvim-cmp) — simpler, fast, prebuilt fuzzy binary.
- Statusline is `lualine` (NvChad's was dropped); shows Obsession status.
- `<Tab>`/`<S-Tab>` are buffer next/prev (no NvChad tabufline here).
- To debug your own C: `clang -g -O0 -o prog prog.c`, then `F5` and enter the
  binary path at the prompt.
