local map = vim.keymap.set

-- General -------------------------------------------------------------------
map("i", "jk", "<ESC>", { desc = "Exit insert mode" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
-- Ctrl-S to save in normal/insert/visual (stays in the current mode)
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit window" })

-- Move through wrapped lines naturally
map({ "n", "v" }, "j", "gj", { desc = "Down (wrapped lines)" })
map({ "n", "v" }, "k", "gk", { desc = "Up (wrapped lines)" })

-- Keep selection when indenting
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- Tmux-aware window navigation (handled by vim-tmux-navigator) ---------------
map("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Window/pane left" })
map("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", { desc = "Window/pane right" })
map("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Window/pane down" })
map("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Window/pane up" })

-- Buffers / tabs ------------------------------------------------------------
-- (Tab is left unmapped so it keeps working as <C-i> / jump-forward.)
map("n", "]b", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer (tab)" })
map("n", "[b", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous buffer (tab)" })
map("n", "<leader>x", "<cmd>bdelete<cr>", { desc = "Close buffer" })

-- Comments (built-in gc/gcc commenting) -------------------------------------
map("n", "<leader>/", "gcc", { remap = true, desc = "Toggle comment line" })
map("x", "<leader>/", "gc", { remap = true, desc = "Toggle comment selection" })

-- Sessions (vim-obsession) --------------------------------------------------
map("n", "<leader>so", "<cmd>Obsession<cr>", { desc = "Toggle session tracking (Obsession)" })

-- Formatting (conform) ------------------------------------------------------
map("n", "<C-M-f>", function()
  require("conform").format { async = true, lsp_format = "fallback" }
end, { desc = "Format buffer" })
map("n", "<leader>cf", function()
  require("conform").format { async = true, lsp_format = "fallback" }
end, { desc = "Format buffer" })
map("n", "<leader>uf", "<cmd>FormatToggle<cr>", { desc = "Toggle autoformat (session)" })
