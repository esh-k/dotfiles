return {
  -- Transparently convert .ipynb <-> percent script (cells = `# %%`)
  {
    "GCBallesteros/jupytext.nvim",
    lazy = false,
    opts = {
      style = "percent",
      output_extension = "auto",
      force_ft = nil,
    },
    config = function(_, opts)
      require("jupytext").setup(opts)
      -- enable ]]/[[ cell navigation in notebook-style buffers
      require("configs.molten").setup()
    end,
  },

  -- Kernel interaction / running cells with inline output
  {
    "benlubas/molten-nvim",
    build = ":UpdateRemotePlugins",
    cmd = { "MoltenInit", "MoltenEvaluateLine", "MoltenEvaluateVisual", "MoltenReevaluateCell" },
    init = function()
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_auto_open_output = false
      vim.g.molten_virt_text_output = true
      vim.g.molten_wrap_output = true
    end,
    keys = {
      {
        "<leader>mi",
        function()
          require("configs.molten").init_kernel()
        end,
        desc = "molten: init kernel (auto-detect project python)",
      },
      { "<leader>mp", "<cmd>MoltenInit<CR>", desc = "molten: pick kernel (manual)" },
      {
        "<leader>mr",
        function()
          require("configs.molten").run_cell()
        end,
        desc = "molten: run cell",
      },
      {
        "<leader>mR",
        function()
          require("configs.molten").run_cell_and_advance()
        end,
        desc = "molten: run cell & advance",
      },
      {
        "<leader>ma",
        function()
          require("configs.molten").run_all()
        end,
        desc = "molten: run all cells",
      },
      { "<leader>ms", "<cmd>MoltenShowOutput<CR>", desc = "molten: show output" },
      { "<leader>mh", "<cmd>MoltenHideOutput<CR>", desc = "molten: hide output" },
      { "<leader>mx", "<cmd>MoltenInterrupt<CR>", desc = "molten: interrupt kernel" },
      {
        "<leader>me",
        ":<C-u>MoltenEvaluateVisual<CR>gv",
        mode = "v",
        desc = "molten: run selection",
      },
    },
  },

  -- Inline image output (plots) — requires a graphics terminal (Ghostty/kitty/
  -- WezTerm) + imagemagick; under tmux: set -g allow-passthrough on.
  {
    "3rd/image.nvim",
    lazy = false,
    opts = {
      backend = "kitty",
      integrations = {
        markdown = {
          enabled = true,
          only_render_image_at_cursor = false,
        },
      },
      max_width_window_percentage = 80,
    },
  },
}
