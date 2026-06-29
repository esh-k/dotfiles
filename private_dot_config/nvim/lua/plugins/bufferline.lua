-- Tabs for open files in the top bar (replaces NvChad's tabufline).
return {
  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false, -- show the tab bar from startup
    opts = function()
      return {
        options = {
          mode = "buffers", -- one entry per open file
          diagnostics = "nvim_lsp",
          show_buffer_close_icons = true,
          show_close_icon = false,
          separator_style = "thin",
          always_show_bufferline = true,
          -- keep the bar clear of the file tree
          offsets = {
            { filetype = "NvimTree", text = "File Explorer", highlight = "Directory", separator = true },
          },
        },
        -- catppuccin-themed highlights
        highlights = require("catppuccin.special.bufferline").get_theme(),
      }
    end,
  },
}
