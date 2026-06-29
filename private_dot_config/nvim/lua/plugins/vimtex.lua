-- LaTeX editing with live PDF: VimTeX drives latexmk in continuous mode, so the
-- PDF recompiles on every save and the viewer updates live.
--
-- BACKEND (install yourself): a TeX distribution providing `latexmk` + a TeX
-- engine (e.g. MacTeX / BasicTeX: `brew install --cask mactex-no-gui` or
-- `brew install basictex` then `tlmgr install latexmk`), and a synctex-capable
-- PDF viewer. Default here is Skim on macOS: `brew install --cask skim`.
return {
  {
    "lervag/vimtex",
    ft = { "tex", "plaintex", "latex" },
    init = function()
      vim.g.vimtex_view_method = "skim" -- macOS viewer with SyncTeX
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_compiler_latexmk = {
        continuous = 1, -- recompile on save -> live PDF updates
        options = {
          "-pdf",
          "-synctex=1",
          "-interaction=nonstopmode",
          "-file-line-error",
          "-shell-escape",
        },
      }
      vim.g.vimtex_quickfix_mode = 0 -- don't steal focus to quickfix on warnings
      vim.g.vimtex_mappings_enabled = 1 -- default <localleader>l... proof/compile maps
      -- VimTeX owns .tex highlighting + conceal; the treesitter latex highlighter
      -- is disabled for tex (see plugins/init.lua treesitter config) to avoid the
      -- conflict.
    end,
    config = function()
      -- Auto-start continuous compilation (live PDF on save) when latexmk exists.
      local function autostart(buf)
        if vim.b[buf].vimtex_autostarted or vim.fn.executable "latexmk" ~= 1 then
          return
        end
        vim.b[buf].vimtex_autostarted = true
        vim.schedule(function()
          pcall(vim.cmd, "VimtexCompile")
        end)
      end
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "tex", "plaintex", "latex" },
        callback = function(ev)
          autostart(ev.buf)
        end,
      })
      -- the buffer that triggered loading already fired FileType
      if vim.tbl_contains({ "tex", "plaintex", "latex" }, vim.bo.filetype) then
        autostart(vim.api.nvim_get_current_buf())
      end
    end,
  },
}
