-- Python / Jupyter notebooks inside Neovim:
--   * jupytext.nvim   - edit .ipynb as a percent-format script (cells = `# %%`)
--   * molten-nvim     - run cells against a Jupyter kernel, output inline
--   * image.nvim      - render plot/image output inline (graphics terminal req'd)
--
-- BACKENDS:
--   * jupytext CLI: installed via Mason (`jupytext` in mason-tool-installer).
--   * molten python deps (pynvim/jupyter_client/ipykernel): NOT available via
--     Mason (it only packages executables, not libraries). They live in a dedicated
--     venv at stdpath('data')/molten-venv, which init.lua points the python3
--     provider at (g:python3_host_prog). Recreate with:
--       python3 -m venv ~/.local/share/nvim_test/molten-venv
--       ~/.local/share/nvim_test/molten-venv/bin/pip install pynvim jupyter_client ipykernel
--       ~/.local/share/nvim_test/molten-venv/bin/python -m ipykernel install --user \
--         --name nvim_test --display-name "Python (nvim_test)"
--     then run :UpdateRemotePlugins.
--   * Inline images: a graphics-capable terminal (kitty/WezTerm/Ghostty) + ImageMagick
--     (`brew install imagemagick`); under tmux `set -g allow-passthrough on`.
return {
  -- transparent .ipynb <-> percent-script conversion -----------------------
  {
    "GCBallesteros/jupytext.nvim",
    lazy = false, -- must register its BufReadCmd before an .ipynb is opened
    opts = {
      style = "percent", -- cells delimited by `# %%`
      output_extension = "auto",
      force_ft = "python",
    },
  },

  -- inline image rendering (used by molten for plots) ----------------------
  {
    "3rd/image.nvim",
    ft = { "python", "markdown" },
    opts = {
      backend = "kitty", -- works in kitty/WezTerm/Ghostty
      processor = "magick_cli", -- use ImageMagick CLI (no luarock needed)
      -- molten drives plot output directly; the markdown integration also renders
      -- images embedded in markdown files (in a graphics terminal like Ghostty).
      integrations = {
        markdown = {
          enabled = true,
          filetypes = { "markdown" },
        },
      },
      max_width_window_percentage = 50,
      max_height_window_percentage = 50,
    },
  },

  -- kernel interaction / running cells -------------------------------------
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    dependencies = { "3rd/image.nvim" },
    build = ":UpdateRemotePlugins", -- registers the python remote plugin
    ft = { "python", "markdown" },
    init = function()
      -- configure molten before it loads
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_auto_open_output = false
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = true -- show text output as virtual lines
      vim.g.molten_virt_lines_off_by_1 = true
    end,
    keys = {
      -- start a kernel: auto-pick the one matching the active venv/conda env,
      -- else fall back to molten's picker
      { "<leader>mi", function() require("configs.molten").init_kernel() end, desc = "Molten: init kernel (auto-detect env)" },
      { "<leader>mp", function() require("configs.molten").pick_kernel() end, desc = "Molten: pick kernel (manual)" },
      -- run current cell / run cell and advance / run all cells
      { "<leader>mr", function() require("configs.molten").run_cell() end, desc = "Molten: run cell" },
      { "<leader>mR", function() require("configs.molten").run_cell_and_advance() end, desc = "Molten: run cell & advance" },
      { "<leader>ma", function() require("configs.molten").run_all() end, desc = "Molten: run all cells" },
      -- run a motion / visual selection
      { "<leader>me", ":<C-u>MoltenEvaluateVisual<cr>", mode = "v", desc = "Molten: evaluate selection" },
      { "<leader>mo", "<cmd>MoltenEvaluateOperator<cr>", desc = "Molten: evaluate operator/motion" },
      -- show / hide / enter cell output
      { "<leader>ms", "<cmd>MoltenShowOutput<cr>", desc = "Molten: show output" },
      { "<leader>mh", "<cmd>MoltenHideOutput<cr>", desc = "Molten: hide output" },
      { "<leader>mO", "<cmd>noautocmd MoltenEnterOutput<cr>", desc = "Molten: enter output window" },
      -- kernel control
      { "<leader>mx", "<cmd>MoltenInterrupt<cr>", desc = "Molten: interrupt kernel" },
      { "<leader>md", "<cmd>MoltenDelete<cr>", desc = "Molten: delete cell output" },
    },
  },
}
