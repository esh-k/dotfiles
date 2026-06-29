-- LSP configuration using the Neovim 0.11+ native vim.lsp.config / enable API
-- (nvim-lspconfig ships the per-server defaults under its lsp/ runtime dir).

-- Completion capabilities advertised to servers (from blink.cmp)
local capabilities = require("blink.cmp").get_lsp_capabilities()
vim.lsp.config("*", { capabilities = capabilities })

-- Per-buffer keymaps, attached when any server connects ---------------------
vim.api.nvim_create_autocmd("LspAttach", {
  desc = "LSP keymaps",
  callback = function(ev)
    local map = function(keys, fn, desc)
      vim.keymap.set("n", keys, fn, { buffer = ev.buf, desc = "LSP: " .. desc })
    end
    map("gd", vim.lsp.buf.definition, "Goto definition")
    map("gD", vim.lsp.buf.declaration, "Goto declaration")
    map("gi", vim.lsp.buf.implementation, "Goto implementation")
    map("gr", vim.lsp.buf.references, "References")
    map("K", vim.lsp.buf.hover, "Hover docs")
    map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
    map("[d", function() vim.diagnostic.jump { count = -1, float = true } end, "Prev diagnostic")
    map("]d", function() vim.diagnostic.jump { count = 1, float = true } end, "Next diagnostic")
  end,
})

-- Server-specific overrides -------------------------------------------------
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
      diagnostics = { globals = { "vim" } },
      telemetry = { enable = false },
    },
  },
})

vim.lsp.config("clangd", {
  cmd = { "clangd", "--background-index", "--clang-tidy" },
})

-- Enable the servers. Names follow nvim-lspconfig's lsp/ definitions.
vim.lsp.enable {
  "lua_ls",
  "clangd",
  "gopls",
  "pyright",
  "bashls",
  "jq_ls",
}
