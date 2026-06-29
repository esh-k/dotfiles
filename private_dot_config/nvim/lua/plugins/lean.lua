-- Lean 4 interactive editing (VS Code-like) via lean.nvim + the `leanls` server.
--
-- BACKEND (install yourself): the Lean toolchain is managed by elan, NOT Mason:
--   curl https://elan.lean-lang.org/elan-init.sh -sSf | sh
--   elan default stable      # installs lean/lake/leanls
-- lean.nvim auto-detects leanls from elan once it is on PATH.
--
-- Completion: leanls inherits blink.cmp capabilities from the global
-- `vim.lsp.config("*", { capabilities = ... })` set in configs/lspconfig.lua, so
-- completion flows through blink.cmp without extra wiring here.
return {
  {
    "Julian/lean.nvim",
    ft = "lean",
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-lua/plenary.nvim",
    },
    -- Modern lean.nvim configures via vim.g.lean_config (setup() is deprecated)
    -- and activates automatically when a Lean file is opened.
    init = function()
      vim.g.lean_config = {
        mappings = true, -- default <LocalLeader> proof / infoview mappings
        infoview = {
          autoopen = true, -- live goal state / hypotheses / term info
          width = 50,
          show_processing = true,
        },
        -- unicode abbreviations: \to -> →, \alpha -> α, etc.
        abbreviations = { enable = true },
      }
    end,
  },
}
