require("nvchad.configs.lspconfig").defaults()

local servers = {
  "html",
  "cssls",
  "gopls",
  "typos_lsp",
}
require("lspconfig").clangd.setup {
  init_options = {
    -- fallbackFlags = { '--std=c++20' }
  },
}
require("lspconfig").typos_lsp.setup({
  cmd_env = { RUST_LOG = "error" },
  init_options = {
    config = '~/code/typos-lsp/crates/typos-lsp/tests/typos.toml',
    diagnosticSeverity = "Error"
  }
})
vim.lsp.set_log_level("debug")
vim.lsp.enable(servers)
-- read :h vim.lsp.config for changing options of lsp servers 
