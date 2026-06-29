return {
  -- Mason + auto-installer for servers / formatters / debug adapters
  {
    "mason-org/mason.nvim",
    lazy = false,
    dependencies = {
      {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        opts = {
          ensure_installed = {
            -- LSP servers
            "lua-language-server",
            "clangd",
            "gopls",
            "pyright",
            "bash-language-server",
            "jq-lsp",
            -- formatters
            "stylua",
            "jq",
            "shfmt",
            "ruff",
            -- debug adapter
            "codelldb",
            -- notebooks
            "jupytext",
          },
          auto_update = false,
          run_on_start = true,
        },
      },
    },
    opts = {},
  },

  -- Completion
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = "InsertEnter",
    opts = {
      keymap = { preset = "default" },
      appearance = { nerd_font_variant = "mono" },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      fuzzy = { implementation = "prefer_rust_with_warning" },
      signature = { enabled = true },
    },
  },

  -- LSP (native vim.lsp.config/enable)
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "saghen/blink.cmp", "mason-org/mason.nvim" },
    config = function()
      require("configs.lspconfig")
    end,
  },

  -- Formatter with session/buffer-scoped format-on-save toggle
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo", "FormatToggle", "FormatEnable", "FormatDisable" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "format buffer/selection",
      },
    },
    opts = require("configs.conform"),
    config = function(_, opts)
      require("conform").setup(opts)

      -- :FormatDisable        -> disable format-on-save for the whole session
      -- :FormatDisable!       -> disable for the current buffer only
      vim.api.nvim_create_user_command("FormatDisable", function(args)
        if args.bang then
          vim.b.disable_autoformat = true
        else
          vim.g.disable_autoformat = true
        end
        vim.notify("format-on-save disabled" .. (args.bang and " (buffer)" or ""))
      end, { desc = "Disable format-on-save", bang = true })

      vim.api.nvim_create_user_command("FormatEnable", function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
        vim.notify("format-on-save enabled")
      end, { desc = "Re-enable format-on-save" })

      vim.api.nvim_create_user_command("FormatToggle", function()
        vim.g.disable_autoformat = not vim.g.disable_autoformat
        vim.notify("format-on-save " .. (vim.g.disable_autoformat and "disabled" or "enabled"))
      end, { desc = "Toggle format-on-save (session)" })
    end,
  },
}
