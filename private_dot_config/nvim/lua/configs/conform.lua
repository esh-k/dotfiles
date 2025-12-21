local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    json = { "jq" },
    python = { 
      "ruff_fix",
      extra_args = { "--lint-unfixable", "F401" },
    },
    -- css = { "prettier" },
    -- html = { "prettier" },
  },

  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options
