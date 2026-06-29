local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.linebreak = true
opt.wrap = true

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

opt.splitright = true
opt.splitbelow = true

opt.termguicolors = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.undofile = true
opt.swapfile = false
opt.updatetime = 250
opt.timeoutlen = 400
opt.scrolloff = 8

-- horizontal scrolling (used by nvim-tree to reach overflowing file names)
opt.sidescroll = 1

-- tabs/buffers in the top bar (bufferline)
opt.showtabline = 2

-- Sessions (vim-obsession). `globals` is required so the grug-far session
-- state (stored in a global) is serialized into Session.vim.
opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,globals"

-- diagnostics
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})
