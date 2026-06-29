-- File explorer (matches the old config's nvim-tree). Long file names that
-- overflow the tree width can be revealed by scrolling horizontally.
return {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },
    keys = {
      { "<C-n>", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" },
      { "<leader>e", "<cmd>NvimTreeFocus<cr>", desc = "Focus file tree" },
    },
    opts = {
      view = {
        width = 32,
        preserve_window_proportions = true, -- carried over from old chadrc
      },
      renderer = {
        group_empty = true,
        root_folder_label = false,
      },
      filters = {
        dotfiles = false, -- show dotfiles; toggle with `H`
      },
      on_attach = function(bufnr)
        local api = require "nvim-tree.api"
        -- keep every default nvim-tree mapping...
        api.config.mappings.default_on_attach(bufnr)

        -- ...then make long names that run off the right edge reachable.
        -- nvim-tree keeps the buffer unwrapped, so we just need smooth
        -- horizontal scrolling + convenient keys for it.
        -- Window options for smooth horizontal scrolling. These must be applied
        -- AFTER nvim-tree finishes setting up its own window options (which it
        -- does post-on_attach), so defer with vim.schedule + the real tree win.
        -- virtualedit=all is the key bit: it lets the cursor sit past a line's
        -- end, so the view scrolls right even when the cursor is on a SHORT
        -- entry. Without it, zl/zh only scroll while on a long name.
        vim.o.sidescroll = 1 -- global: scroll one column at a time (smooth)
        vim.schedule(function()
          local win = vim.fn.bufwinid(bufnr)
          if win ~= -1 then
            vim.wo[win].wrap = false
            vim.wo[win].sidescrolloff = 0
            vim.wo[win].virtualedit = "all"
          end
        end)

        local function map(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = bufnr, noremap = true, silent = true, nowait = true, desc = "nvim-tree: " .. desc })
        end
        -- Horizontal scroll. h/l are unused by nvim-tree's defaults, so they're
        -- repurposed here. Each press jumps half the tree width, so overflowing
        -- file names become visible immediately (a 1-column scroll is too subtle).
        local function hscroll(dir)
          return function()
            local step = math.max(1, math.floor(vim.api.nvim_win_get_width(0) / 2))
            vim.cmd("normal! " .. step .. (dir == "right" and "zl" or "zh"))
          end
        end
        map("<M-l>", hscroll "right", "scroll right (half width)")
        map("<M-h>", hscroll "left", "scroll left (half width)")
        -- jump fully to the end of the longest name / back to the start
        map("<End>", "g$", "scroll to line end")
        map("<Home>", "g0", "scroll to line start")
      end,
    },
  },
}
