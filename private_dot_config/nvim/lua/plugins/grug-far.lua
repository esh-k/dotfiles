-- Project-wide search & replace presented in a single editable buffer:
-- type a search + replacement, see every match across files, and apply them
-- all at once. Backed by ripgrep (already installed).
return {
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    -- init runs at startup (even though the plugin is lazy) so the session
    -- save/restore autocmds exist before any session is loaded.
    init = function()
      require("configs.grug_far_session").setup()
    end,
    opts = {
      headerMaxWidth = 80,
      -- persistent search history (browse with <localleader>t, pick with <CR>);
      -- these are the defaults, stated explicitly for clarity.
      history = {
        maxHistoryLines = 10000,
        historyDir = vim.fn.stdpath "state" .. "/grug-far",
        autoSave = { enabled = true, onReplace = true, onSyncAll = true, onBufDelete = true },
      },
    },
    keys = {
      {
        "<leader>sr",
        function()
          require("grug-far").open()
        end,
        desc = "Search & replace (project)",
      },
      {
        "<leader>sw",
        function()
          require("grug-far").open { prefills = { search = vim.fn.expand "<cword>" } }
        end,
        desc = "Search & replace word under cursor",
      },
      {
        "<leader>sr",
        mode = "v",
        function()
          -- limit the replace to the visually selected range
          require("grug-far").with_visual_selection { prefills = { paths = vim.fn.expand "%" } }
        end,
        desc = "Search & replace in selection",
      },
    },
  },
}
