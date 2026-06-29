-- LSP, Mason (package manager), completion and the conform formatter.
return {
  -- Mason: install LSP servers / formatters / debuggers ---------------------
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    opts = { ui = { border = "rounded" } },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    lazy = false,
    opts = {
      ensure_installed = {
        -- LSP servers
        "lua-language-server",
        "clangd",
        "gopls",
        "pyright",
        "bash-language-server",
        "jq-lsp",
        -- Formatters
        "stylua",
        "clang-format",
        "shfmt",
        "jq",
        "ruff",
        -- Notebooks: jupytext CLI used by jupytext.nvim to convert .ipynb <-> .py
        "jupytext",
        -- Debugger
        "codelldb",
      },
      auto_update = false,
      run_on_start = true,
    },
  },

  -- Completion engine (replaces NvChad's nvim-cmp setup) -------------------
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = "InsertEnter",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = { preset = "default" }, -- C-n/C-p/C-y, C-space to open
      appearance = { nerd_font_variant = "mono" },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        accept = { auto_brackets = { enabled = true } },
      },
      signature = { enabled = true },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
  },

  -- LSP --------------------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "saghen/blink.cmp", "mason-org/mason.nvim" },
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- Formatter --------------------------------------------------------------
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo", "FormatToggle", "FormatEnable", "FormatDisable" },
    config = function()
      require "configs.conform"
    end,
  },
}
