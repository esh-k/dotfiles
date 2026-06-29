-- Conform options. Format-on-save is gated on a flag so it can be toggled per
-- session (vim.g.disable_autoformat) or per buffer (vim.b.disable_autoformat).
-- The Format{Toggle,Enable,Disable} user commands are defined in plugins/lsp.lua.

return {
  formatters_by_ft = {
    lua = { "stylua" },
    json = { "jq" },
    python = { "ruff_format" },
    sh = { "shfmt" },
    bash = { "shfmt" },
    zsh = { "shfmt" },
    c = { "clang_format" },
    cpp = { "clang_format" },
  },

  formatters = {
    shfmt = {
      append_args = { "-i", "4", "-ci", "-ln=auto" },
    },
  },

  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
    return { timeout_ms = 500, lsp_format = "fallback" }
  end,
}
