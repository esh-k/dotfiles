return {
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    keys = {
      {
        "<leader>sr",
        function()
          require("grug-far").open()
        end,
        desc = "search & replace (project-wide)",
      },
      {
        "<leader>sr",
        function()
          require("grug-far").with_visual_selection({ visualSelectionUsage = "operate-within-range" })
        end,
        mode = "v",
        desc = "search & replace (within selection)",
      },
      {
        "<leader>sw",
        function()
          require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
        end,
        desc = "search & replace word under cursor",
      },
    },
    opts = {
      -- single editable buffer: type search + replacement, see all matches, apply
      keymaps = {
        replace = { n = "<localleader>r" },
        syncLocations = { n = "<localleader>s" },
        historyOpen = { n = "<localleader>t" },
      },
      -- history is persistent by default (auto-saved to stdpath('state')/grug-far)
      history = {
        autoSave = { enabled = true },
      },
    },
    init = function()
      -- restore an open search on session reload (see configs/grug_far_session.lua)
      require("configs.grug_far_session").setup()
    end,
  },
}
