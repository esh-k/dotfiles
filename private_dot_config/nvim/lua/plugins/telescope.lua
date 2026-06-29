return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-telescope/telescope-live-grep-args.nvim",
      {
        "nvim-telescope/telescope-smart-history.nvim",
        dependencies = { "kkharji/sqlite.lua" },
      },
    },
    keys = function()
      local persist = require("configs.telescope_persist")
      local builtin = function(name)
        return function()
          require("telescope.builtin")[name]()
        end
      end
      return {
        -- find files / live grep restore the last typed prompt
        { "<leader>ff", persist.files, desc = "find files (restore last input)" },
        { "<leader>fg", persist.grep, desc = "live grep (args, restore last input)" },
        { "<leader>fb", builtin("buffers"), desc = "buffers" },
        { "<leader>fo", builtin("oldfiles"), desc = "recent files" },
        { "<leader>fr", builtin("resume"), desc = "resume last picker" },
        { "<leader>fm", builtin("marks"), desc = "marks viewer" },
        { "<leader>fz", builtin("current_buffer_fuzzy_find"), desc = "fuzzy find in buffer" },
        {
          "<leader>fp",
          function()
            require("configs.search_history").open()
          end,
          desc = "browse all past searches",
        },
        { "<leader>sh", builtin("search_history"), desc = "/-search history" },
        { "<leader>sc", builtin("command_history"), desc = ":-command history" },
      }
    end,
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local lga_actions = require("telescope-live-grep-args.actions")
      local lga_quote = require("configs.lga_quote")

      telescope.setup({
        defaults = {
          path_display = { "smart" },
          -- history backend: telescope-smart-history (per-prompt recall + DB)
          history = {
            path = vim.fn.stdpath("data") .. "/telescope_history.sqlite3",
            limit = 1000,
          },
          mappings = {
            i = {
              -- preview scroll (telescope defaults) + results page-scroll
              ["<C-d>"] = actions.preview_scrolling_down,
              ["<C-u>"] = actions.preview_scrolling_up,
              ["<M-d>"] = actions.results_scrolling_down,
              ["<M-u>"] = actions.results_scrolling_up,
              -- cycle previous prompts (works in current session too)
              ["<C-Up>"] = actions.cycle_history_prev,
              ["<C-Down>"] = actions.cycle_history_next,
            },
            n = {
              ["<C-d>"] = actions.preview_scrolling_down,
              ["<C-u>"] = actions.preview_scrolling_up,
              ["<M-d>"] = actions.results_scrolling_down,
              ["<M-u>"] = actions.results_scrolling_up,
              ["<C-Up>"] = actions.cycle_history_prev,
              ["<C-Down>"] = actions.cycle_history_next,
            },
          },
        },
        extensions = {
          live_grep_args = {
            auto_quoting = true,
            mappings = {
              i = {
                -- quote term + append include glob
                ["<C-g>"] = lga_quote.quote_or_append(" --iglob "),
                -- quote term + append exclude glob
                ["<M-g>"] = lga_quote.quote_or_append(" --iglob !"),
                -- switch to a fuzzy refine over the current results.
                -- NOTE: this is the telescope *core* action, NOT an lga action —
                -- the installed lga only exports `quote_prompt`, so
                -- lga_actions.to_fuzzy_refine was nil (old <C-space> did nothing).
                ["<C-y>"] = actions.to_fuzzy_refine,
              },
            },
          },
        },
      })

      telescope.load_extension("fzf")
      telescope.load_extension("live_grep_args")
      telescope.load_extension("smart_history")

      -- keep the lga_actions require meaningful (avoids "unused" + documents intent)
      _ = lga_actions

      require("configs.telescope_persist").setup()
    end,
  },
}
