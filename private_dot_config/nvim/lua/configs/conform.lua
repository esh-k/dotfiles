-- Formatter setup. Autoformat-on-save can be toggled for the session with
-- :FormatToggle / :FormatEnable / :FormatDisable (or <leader>uf).
local conform = require "conform"

conform.setup {
  formatters_by_ft = {
    lua = { "stylua" },
    c = { "clang-format" },
    cpp = { "clang-format" },
    python = { "ruff_format" },
    json = { "jq" },
    sh = { "shfmt" },
    bash = { "shfmt" },
    zsh = { "shfmt" },
  },
  formatters = {
    shfmt = { prepend_args = { "-i", "4", "-ci" } },
  },
  -- Decide at format time whether autoformat-on-save is enabled.
  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
    return { timeout_ms = 1000, lsp_format = "fallback" }
  end,
}

-- Commands to enable/disable formatting in the current session ---------------
-- A bang (!) scopes the change to the current buffer only.
vim.api.nvim_create_user_command("FormatDisable", function(args)
  if args.bang then
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
  vim.notify("Autoformat disabled" .. (args.bang and " (buffer)" or " (session)"), vim.log.levels.INFO)
end, { bang = true, desc = "Disable autoformat-on-save" })

vim.api.nvim_create_user_command("FormatEnable", function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
  vim.notify("Autoformat enabled", vim.log.levels.INFO)
end, { desc = "Enable autoformat-on-save" })

vim.api.nvim_create_user_command("FormatToggle", function()
  vim.g.disable_autoformat = not vim.g.disable_autoformat
  vim.notify("Autoformat " .. (vim.g.disable_autoformat and "disabled" or "enabled"), vim.log.levels.INFO)
end, { desc = "Toggle autoformat-on-save (session)" })
