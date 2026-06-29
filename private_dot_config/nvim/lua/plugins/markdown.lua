-- In-buffer markdown rendering (headings, code blocks, tables, lists) plus
-- LaTeX equation rendering. Works in any terminal incl. Ghostty.
--
-- LaTeX math (`$...$`, `$$...$$`) is converted to readable Unicode via
-- pylatexenc's `latex2text` (installed in the molten venv). For fully graphical
-- (KaTeX) equations, use the browser preview: :MarkdownPreview.
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "markdown_inline" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      latex = {
        enabled = true,
        -- absolute path so it works regardless of $PATH
        converter = vim.fn.stdpath "data" .. "/molten-venv/bin/latex2text",
        highlight = "RenderMarkdownMath",
        position = "above",
      },
      code = { sign = false, width = "block", border = "thin" },
      heading = { sign = false },
    },
    keys = {
      { "<leader>um", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle markdown rendering" },
    },
  },

  -- Full graphical preview in the browser: KaTeX LaTeX, embedded images, AND
  -- mermaid diagrams (all bundled by markdown-preview). This is the reliable way
  -- to render mermaid graphs -- there is no standard inline-terminal mermaid
  -- renderer; in the buffer, image.nvim handles images and render-markdown shows
  -- LaTeX as unicode.
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && npm install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    keys = {
      { "<leader>up", "<cmd>MarkdownPreviewToggle<cr>", desc = "Toggle markdown browser preview (KaTeX)" },
    },
  },
}
