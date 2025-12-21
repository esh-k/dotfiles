require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

-- Bad since doesn't support repating f commands
-- map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("n", "<C-h>", "<cmd> TmuxNavigateLeft<CR>", { desc = "window left" })
map("n", "<C-l>", "<cmd> TmuxNavigateRight<CR>", { desc = "window right" })
map("n", "<C-j>", "<cmd> TmuxNavigateDown<CR>", { desc = "window down" })
map("n", "<C-k>", "<cmd> TmuxNavigateUp<CR>", { desc = "window up" })

map("n", "j", "gj", { desc = "move down between wrapped lines" })
map("n", "k", "gk", { desc = "move up between wrapped lines" })
map("v", "j", "gj", { desc = "move down between wrapped lines" })
map("v", "k", "gk", { desc = "move up between wrapped lines" })

-- Override Tab mapping to use different keys so C-i can work for jump forward
-- C-i and Tab are the same keycode, so we need to change Tab to something else
if require("nvconfig").ui.tabufline.enabled then
  -- Unmap Tab from buffer navigation
  vim.keymap.del("n", "<Tab>")
  vim.keymap.del("n", "<S-Tab>")
end

vim.keymap.set("n", "<C-M-f>",
  function()
    require("conform").format({
    async = true,
    lsp_fallback = true,
  })
  end,
  { noremap = true, silent=true}
)

vim.keymap.set('n', '<F5>', function() require('dap').continue() end)
    vim.keymap.set('n', '<F10>', function() require('dap').step_over() end)
    vim.keymap.set('n', '<F11>', function() require('dap').step_into() end)
    vim.keymap.set('n', '<F12>', function() require('dap').step_out() end)
    vim.keymap.set('n', '<Leader>b', function() require('dap').toggle_breakpoint() end)
    vim.keymap.set('n', '<Leader>B', function() require('dap').set_breakpoint() end)
    vim.keymap.set('n', '<Leader>lp', function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end)
    vim.keymap.set('n', '<Leader>dr', function() require('dap').repl.open() end)
    vim.keymap.set('n', '<Leader>dl', function() require('dap').run_last() end)
    vim.keymap.set({'n', 'v'}, '<Leader>dh', function()
      require('dap.ui.widgets').hover()
    end)
    vim.keymap.set({'n', 'v'}, '<Leader>dp', function()
      require('dap.ui.widgets').preview()
    end)
    vim.keymap.set('n', '<Leader>df', function()
      local widgets = require('dap.ui.widgets')
      widgets.centered_float(widgets.frames)
    end)
    vim.keymap.set('n', '<Leader>ds', function()
      local widgets = require('dap.ui.widgets')
      widgets.centered_float(widgets.scopes)
    end)
-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
