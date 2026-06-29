local map = vim.keymap.set

-- escape from insert
map("i", "jk", "<ESC>", { desc = "escape insert mode" })

-- tmux-aware window navigation
map("n", "<C-h>", "<cmd>TmuxNavigateLeft<CR>", { desc = "window left" })
map("n", "<C-l>", "<cmd>TmuxNavigateRight<CR>", { desc = "window right" })
map("n", "<C-j>", "<cmd>TmuxNavigateDown<CR>", { desc = "window down" })
map("n", "<C-k>", "<cmd>TmuxNavigateUp<CR>", { desc = "window up" })

-- move through wrapped lines naturally
map({ "n", "v" }, "j", "gj", { desc = "down (wrapped lines)" })
map({ "n", "v" }, "k", "gk", { desc = "up (wrapped lines)" })

-- save
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR>", { desc = "save file" })

-- clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "clear search highlight" })

-- sessions (vim-obsession)
map("n", "<leader>so", "<cmd>Obsession<CR>", { desc = "toggle session (Obsession)" })

-- comment toggle (built-in gc/gcc). remap = true so the <Plug> operator fires.
map("n", "<leader>/", "gcc", { remap = true, desc = "toggle comment" })
map("v", "<leader>/", "gc", { remap = true, desc = "toggle comment" })

-- formatting (conform)
map({ "n", "v" }, "<C-M-f>", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "format buffer/selection" })
map({ "n", "v" }, "<leader>cf", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "format buffer/selection" })
map("n", "<leader>uf", "<cmd>FormatToggle<CR>", { desc = "toggle format-on-save (session)" })
