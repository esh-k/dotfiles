local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    json = { "jq" },
    python = { 
      "ruff_fix",
      extra_args = { "--lint-unfixable", "F401" },
    },
    sql = {
      "sql_formatter",
    }
    -- css = { "prettier" },
    -- html = { "prettier" },
  },

  formatters = {
    sql_formatter = {
      args = { "-c" , '{"keywordCase": "upper", "tabWidth": "4"}' },
    },
  },

  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options
