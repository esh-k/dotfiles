local autocmd = vim.api.nvim_create_autocmd

-- Highlight text on yank
autocmd("TextYankPost", {
  desc = "Highlight on yank",
  callback = function()
    vim.highlight.on_yank { timeout = 150 }
  end,
})

-- Trim trailing whitespace on save (formatters handle most files, this is a
-- safety net for filetypes without a configured formatter)
autocmd("BufWritePre", {
  desc = "Trim trailing whitespace",
  callback = function()
    if vim.bo.binary or vim.bo.filetype == "diff" or not vim.bo.modifiable then
      return
    end
    local view = vim.fn.winsaveview()
    vim.cmd [[keeppatterns %s/\s\+$//e]]
    vim.fn.winrestview(view)
  end,
})

-- Close some utility buffers with `q`
autocmd("FileType", {
  pattern = { "help", "qf", "man", "lspinfo", "checkhealth", "dap-float" },
  callback = function(args)
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = args.buf, silent = true })
  end,
})

-- Notebook cell navigation: [[ / ]] jump between `# %%` markers, but only in
-- buffers that actually use them (so plain .py files keep the default motions).
autocmd("FileType", {
  pattern = { "python", "markdown" },
  desc = "Cell navigation in notebook-style buffers",
  callback = function(args)
    local has_cell = false
    for _, l in ipairs(vim.api.nvim_buf_get_lines(args.buf, 0, -1, false)) do
      if l:match "^#%s*%%%%" then
        has_cell = true
        break
      end
    end
    if not has_cell then
      return
    end
    local m = require "configs.molten"
    vim.keymap.set("n", "]]", m.next_cell, { buffer = args.buf, silent = true, desc = "Next cell (# %%)" })
    vim.keymap.set("n", "[[", m.prev_cell, { buffer = args.buf, silent = true, desc = "Prev cell (# %%)" })
  end,
})
