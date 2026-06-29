return {
  -- Rocq/Coq, Proof-General style interactive stepping with goals + info panels.
  -- BACKEND: `brew install coq` (or `opam install coq`) + `pip install pynvim`
  -- (Coqtail needs the python3 provider, else its commands don't register).
  {
    "whonore/Coqtail",
    ft = "coq",
    init = function()
      -- map .v to filetype `coq` so the lazy `ft` trigger fires
      vim.filetype.add({ extension = { v = "coq" } })

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("coqtail_keys", { clear = true }),
        pattern = "coq",
        callback = function(ev)
          local function m(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = "coq: " .. desc })
          end
          m("<localleader>cc", "<cmd>CoqStart<CR>", "start")
          m("<localleader>cq", "<cmd>CoqStop<CR>", "stop")
          m("<localleader>j", "<cmd>CoqNext<CR>", "step forward")
          m("<localleader>k", "<cmd>CoqUndo<CR>", "step back")
          m("<localleader>l", "<cmd>CoqToLine<CR>", "run to cursor")
          m("<localleader>cg", "<cmd>CoqJumpToEnd<CR>", "go to goal / end of checked region")
        end,
      })
    end,
  },
}
