return {
  -- In-buffer rendering: headings/code/tables/lists + $...$/$$...$$ math via
  -- pylatexenc's latex2text (installed in the molten venv).
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      latex = {
        enabled = true,
        converter = vim.fn.stdpath("data") .. "/molten-venv/bin/latex2text",
      },
    },
    keys = {
      { "<leader>um", "<cmd>RenderMarkdown toggle<CR>", desc = "toggle markdown rendering" },
    },
  },

  -- Fully graphical preview in the browser (bundles KaTeX + mermaid + images).
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && npm install",
    ft = { "markdown" },
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    keys = {
      { "<leader>up", "<cmd>MarkdownPreviewToggle<CR>", desc = "markdown preview (browser)" },
    },
  },
}
