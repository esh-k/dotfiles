-- Native LSP config (Neovim 0.11+): vim.lsp.config / vim.lsp.enable instead of
-- the old require('lspconfig').xxx.setup{}. Server names follow nvim-lspconfig's
-- lsp/ dir. Completion capabilities come from blink.cmp.

local ok_blink, blink = pcall(require, "blink.cmp")
local capabilities = ok_blink and blink.get_lsp_capabilities()
  or vim.lsp.protocol.make_client_capabilities()

-- defaults applied to every server
vim.lsp.config("*", {
  capabilities = capabilities,
})

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      workspace = { checkThirdParty = false },
    },
  },
})

local servers = { "lua_ls", "clangd", "gopls", "pyright", "bashls", "jq_ls" }
vim.lsp.enable(servers)

-- keymaps on attach
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_attach_keys", { clear = true }),
  callback = function(ev)
    local function m(lhs, rhs, desc, mode)
      vim.keymap.set(mode or "n", lhs, rhs, { buffer = ev.buf, desc = "lsp: " .. desc })
    end
    m("gd", vim.lsp.buf.definition, "goto definition")
    m("gD", vim.lsp.buf.declaration, "goto declaration")
    m("gi", vim.lsp.buf.implementation, "goto implementation")
    m("gr", vim.lsp.buf.references, "references")
    m("K", vim.lsp.buf.hover, "hover")
    m("<leader>cr", vim.lsp.buf.rename, "rename")
    m("<leader>ca", vim.lsp.buf.code_action, "code action", { "n", "v" })
    m("[d", function()
      vim.diagnostic.jump({ count = -1 })
    end, "prev diagnostic")
    m("]d", function()
      vim.diagnostic.jump({ count = 1 })
    end, "next diagnostic")
  end,
})
