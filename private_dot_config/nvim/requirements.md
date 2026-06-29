# Requirements
I'm starting a new neovim config where I want the main structure to resemble the existing config in @~/.config/nvim/ but don't use a starter config like nvchad to achieve this.
- Obsession to save and restore vim sessions
- Lazy.nvim as my package manager
- Telescope or something equivalent for searching, fuzzy find files,
    - A window to view and search through marks
    - have a history of previous searches
- Easy navigation that is compatible with tmux
- Lsp server
- Debugger with full keybindings
    - Verify that the debugger works using a simple c project
- Mason for easy installing of packages; setup similar to existing config
- Formatter where I can use a command to enable or disable formatting in the current session
- Cheat sheet of all the keybindings I can refer
    - show hints for multi character command
    - this is present in the existing config in nvchad and I want this as well
- Theme like catpuccin from my existing config
- Add directory tree where I can scroll to the right if there are some files that are hidden to the right
- Multi search and replace as if in a single buffer
- Python/Jupyter notebooks: edit and run `.ipynb` files inside Neovim with a
  Jupyter kernel, executing cells and showing output (text + plots/images) inline.
    - Use `jupytext.nvim` to transparently convert `.ipynb` <-> plaintext
      (cells delimited by `# %%`) so notebooks are edited as scripts and saved
      back to `.ipynb`.
    - Use `molten-nvim` for kernel interaction / running cells, and `image.nvim`
      for inline image output (graphics-capable terminal required: kitty/WezTerm/
      Ghostty; under tmux enable `allow-passthrough`).
    - Keybindings to: start/select a kernel, run the current cell, run cell and
      advance, run all cells, and show/hide cell output.
- Rocq (formerly Coq) proof assistant support, similar to Proof General for emacs:
    - Interactive proof stepping: step forward / step back / run-to-cursor, with a
      goals panel and a messages/info panel.
    - Prefer `whonore/Coqtail` (Proof-General-style interactive stepping driving
      `coqtop`/`rocq`), or the LSP-based `coq-lsp` + `tomtomjhj/coq-lsp.nvim`
      (continuous checking + goal/info panels) — pick whichever integrates more
      cleanly with the current Rocq toolchain.
    - Verify with a small `.v` file: step through a simple proof and confirm the
      goals panel updates and the proof completes (`Qed.`).
- Lean 4 interactive editing, similar to the VS Code Lean experience:
    - Use `lean.nvim` (built on the Lean `leanls` LSP server) with an infoview
      panel showing the live goal state / hypotheses / term info at the cursor,
      interactive clickable goals & diagnostics, and unicode abbreviation input
      (e.g. `\to` -> `->`). Wire completion through the existing `blink.cmp`.
    - The Lean toolchain is managed by `elan` (not Mason), so the server is
      installed separately from the Mason-managed tools.
    - Verify with a small `.lean` file: move through a simple proof and confirm
      the infoview updates with the goal state and the proof completes.
- Add tabs for file names in the top bar
- Add `<leader>/` to toggle comment
- Markdown rendering support with ability to render images, latex equations, and if possible mermaid graph assuming ghostty terminal.
- Latex editing support that on save will render to a pdf (live updates).

## Running and verification
- Use `NVIM_APPNAME=nvim_test nvim` to run neovim on the test config
- Use headless mode and cli to verify if everything is working as expected
