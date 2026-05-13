require("nvchad.configs.lspconfig").defaults()

local servers = {
  "html",
  "cssls",
  "gopls",
  "typos_lsp",
  "clangd",
  "pyright",
  "jq-lsp",
  "slqfluff",
}
vim.lsp.config('clangd', {
  init_options = {
    -- fallbackFlags = { '--std=c++20' }
  },
})
vim.lsp.config('typos_lsp', {
  cmd_env = { RUST_LOG = "error" },
  init_options = {
    config = '~/code/typos-lsp/crates/typos-lsp/tests/typos.toml',
    diagnosticSeverity = "Warning"
  }
})
vim.lsp.set_log_level("debug")
vim.lsp.enable(servers)
-- read :h vim.lsp.config for changing options of lsp servers 
