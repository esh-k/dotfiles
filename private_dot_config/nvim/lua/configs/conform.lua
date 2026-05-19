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
		},
		sh = { "shfmt" },
		bash = { "shfmt" },
		zsh = { "shfmt" },
		-- css = { "prettier" },
		-- html = { "prettier" },
	},

	formatters = {
		sql_formatter = {
			args = { "-c", '{"keywordCase": "upper", "tabWidth": "4"}' },
		},
		shfmt = {
			prepend_args = { "-i", "4", "-ci", "-ln=auto", "-d", "--severity=warning" },
		},
	},

	format_on_save = {
		-- These options will be passed to conform.format()
		timeout_ms = 500,
		lsp_fallback = true,
	},
}

return options
