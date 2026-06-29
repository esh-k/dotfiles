-- Rocq/Coq proof assistant, Proof-General style, via Coqtail (drives coqtop/rocq).
-- Coqtail opens a goals panel + an info/messages panel on :CoqStart and supports
-- interactive stepping.
--
-- BACKEND (install yourself): a Coq/Rocq toolchain on PATH (coqtop/coqidetop),
--   e.g. `brew install coq`  or via opam: `opam install coq`.
--   Coqtail also needs the python3 provider: `pip install pynvim`.
return {
  {
    "whonore/Coqtail",
    ft = "coq",
    init = function()
      -- Define our own mappings (below) instead of Coqtail's defaults.
      vim.g.coqtail_nomap = 1
      -- *.v isn't detected as coq until Coqtail loads; register it ourselves so
      -- the `ft = "coq"` lazy trigger fires when a .v file is opened.
      vim.filetype.add { extension = { v = "coq" } }
    end,
    config = function()
      local function set_maps(buf)
        local map = function(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, desc = "Coq: " .. desc })
        end
        map("<localleader>cc", "<cmd>CoqStart<cr>", "start")
        map("<localleader>cq", "<cmd>CoqStop<cr>", "stop")
        map("<localleader>j", "<cmd>CoqNext<cr>", "step forward")
        map("<localleader>k", "<cmd>CoqUndo<cr>", "step back")
        map("<localleader>l", "<cmd>CoqToLine<cr>", "run to cursor")
        map("<localleader>G", "<cmd>CoqJumpToEnd<cr>", "jump to end of checked region")
        map("<localleader>cg", "<cmd>CoqGotoGoal<cr>", "go to goal")
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "coq",
        callback = function(ev)
          set_maps(ev.buf)
        end,
      })
      -- the buffer that triggered loading already fired FileType, so map it now
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].filetype == "coq" then
          set_maps(b)
        end
      end
    end,
  },
}
