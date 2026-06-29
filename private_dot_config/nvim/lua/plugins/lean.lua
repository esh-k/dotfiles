return {
  {
    "Julian/lean.nvim",
    ft = "lean",
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-lua/plenary.nvim",
    },
    -- Configured via vim.g.lean_config (lean.setup() is deprecated). The leanls
    -- server is managed by elan (NOT Mason). Completion is inherited from the
    -- global vim.lsp.config("*") capabilities (blink.cmp).
    init = function()
      vim.g.lean_config = {
        mappings = true, -- default <LocalLeader> proof/infoview maps
        lsp = { enable = true },
        infoview = {
          autoopen = true,
          show_processing = true,
        },
        abbreviations = {
          enable = true, -- unicode input: \to -> →
        },
      }
    end,
  },
}
