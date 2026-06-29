return {
  -- LaTeX editing + live PDF: latexmk continuous mode recompiles on every save;
  -- viewer is Skim (macOS, SyncTeX). VimTeX owns .tex highlighting/conceal
  -- (treesitter's latex highlighter is disabled for tex in plugins/init.lua).
  -- BACKEND: a TeX distro with `latexmk` (MacTeX/BasicTeX) + Skim.
  {
    "lervag/vimtex",
    ft = { "tex", "latex" },
    init = function()
      vim.g.vimtex_view_method = "skim"
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_compiler_latexmk = { continuous = 1 }
      vim.g.vimtex_mappings_enabled = 1
      vim.g.vimtex_quickfix_mode = 0

      -- auto-start continuous compilation when opening a .tex (guarded on
      -- latexmk being installed, so it safely no-ops otherwise)
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("vimtex_autostart", { clear = true }),
        pattern = "tex",
        callback = function()
          if vim.fn.executable("latexmk") == 1 then
            vim.schedule(function()
              pcall(vim.cmd, "VimtexCompile")
            end)
          end
        end,
      })
    end,
  },
}
