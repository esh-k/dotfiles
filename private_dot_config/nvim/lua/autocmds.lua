local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- highlight on yank
autocmd("TextYankPost", {
  group = augroup("yank_highlight", { clear = true }),
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})

-- trim trailing whitespace on save
autocmd("BufWritePre", {
  group = augroup("trim_whitespace", { clear = true }),
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- press `q` to close throwaway windows
autocmd("FileType", {
  group = augroup("q_close", { clear = true }),
  pattern = { "help", "qf", "man", "lspinfo", "checkhealth", "startuptime", "query" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, silent = true, nowait = true })
  end,
})
