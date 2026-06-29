return {
  {
    "akinsho/bufferline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin/nvim" },
    keys = {
      { "]b", "<cmd>BufferLineCycleNext<CR>", desc = "next buffer/tab" },
      { "[b", "<cmd>BufferLineCyclePrev<CR>", desc = "prev buffer/tab" },
      { "<leader>x", "<cmd>bdelete<CR>", desc = "close buffer" },
    },
    opts = function()
      return {
        highlights = require("catppuccin.special.bufferline").get_theme(),
        options = {
          mode = "buffers",
          diagnostics = "nvim_lsp",
          always_show_bufferline = true,
          offsets = {
            {
              filetype = "NvimTree",
              text = "File Explorer",
              highlight = "Directory",
              separator = true,
            },
          },
        },
      }
    end,
  },
}
