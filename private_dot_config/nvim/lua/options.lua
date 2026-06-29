local opt = vim.opt
local o = vim.o

o.number = true
o.relativenumber = false
o.numberwidth = 2
o.signcolumn = "yes"
o.cursorline = true
o.scrolloff = 8
o.sidescrolloff = 8

-- indentation
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.softtabstop = 2
o.smartindent = true

-- search
o.ignorecase = true
o.smartcase = true
o.hlsearch = true
o.incsearch = true

-- ui / wrapping
o.wrap = true -- soft-wrap long lines
opt.linebreak = true -- wrap on word boundaries, not mid-word
o.breakindent = true -- wrapped lines keep the original indentation
o.termguicolors = true
o.showmode = false -- statusline shows the mode
o.splitright = true
o.splitbelow = true
o.mouse = "a"
o.clipboard = "unnamedplus"

-- files / undo
o.undofile = true
o.swapfile = false
o.updatetime = 250
o.timeoutlen = 400 -- which-key popup delay

-- completion
opt.completeopt = { "menu", "menuone", "noselect" }

-- sessions: which state Obsession/:mksession should persist.
opt.sessionoptions = { "buffers", "curdir", "folds", "help", "tabpages", "winsize", "winpos", "terminal", "globals" }

-- diagnostics: inline virtual text + signs
vim.diagnostic.config {
  virtual_text = { prefix = "●" },
  severity_sort = true,
  float = { border = "rounded", source = true },
}
