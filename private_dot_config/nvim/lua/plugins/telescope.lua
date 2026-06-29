-- Fuzzy finder: files, grep (with include/exclude globs), marks viewer, and
-- persistent search/command history.
return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- native fzf sorter for speed (built with make)
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      -- type ripgrep args (globs / include / exclude) directly in the prompt
      "nvim-telescope/telescope-live-grep-args.nvim",
      -- persist picker prompt history across restarts (sqlite-backed)
      "nvim-telescope/telescope-smart-history.nvim",
      "kkharji/sqlite.lua",
    },
    keys = {
      -- Files / content
      -- find_files / live grep reopen pre-filled with the last prompt you typed
      -- (even if never submitted) via configs.telescope_persist.
      {
        "<leader>ff",
        function()
          require("configs.telescope_persist").find_files()
        end,
        desc = "Find files (restores last input)",
      },
      -- Live grep. To include/exclude paths, QUOTE the search term first
      -- (press <C-g> in the prompt -> it quotes the term and appends ' --iglob ')
      -- then type a glob, e.g.  "foo" --iglob *.lua   or   "foo" --iglob !build/**
      {
        "<leader>fg",
        function()
          require("configs.telescope_persist").live_grep_args()
        end,
        desc = "Live grep (restores last input; <C-g>/<M-g> for globs)",
      },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
      { "<leader>fo", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
      { "<leader>fr", "<cmd>Telescope resume<cr>", desc = "Resume last picker" },
      { "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Fuzzy find in buffer" },
      -- A window to view and search through marks
      { "<leader>fm", "<cmd>Telescope marks<cr>", desc = "Marks (view & search)" },
      -- Browsable window of previous searches (persistent), plus / and : history
      {
        "<leader>fp",
        function()
          require("configs.search_history").history()
        end,
        desc = "Search history — all pickers (browse & re-run)",
      },
      { "<leader>sh", "<cmd>Telescope search_history<cr>", desc = "Search (/) history" },
      { "<leader>sc", "<cmd>Telescope command_history<cr>", desc = "Command (:) history" },
      { "<leader>sd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
      { "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
    },
    config = function()
      local telescope = require "telescope"
      local actions = require "telescope.actions"

      telescope.setup {
        defaults = {
          prompt_prefix = "   ",
          selection_caret = "  ",
          entry_prefix = "  ",
          sorting_strategy = "ascending",
          -- shorten/elide the common base-directory prefix in results
          path_display = { "smart" },
          layout_config = {
            horizontal = { prompt_position = "top", preview_width = 0.55 },
            width = 0.87,
            height = 0.80,
          },
          -- persistent prompt history, cycled with <C-Up>/<C-Down> in the prompt
          history = {
            path = vim.fn.stdpath "data" .. "/telescope_history.sqlite3",
            limit = 200,
          },
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-Down>"] = actions.cycle_history_next,
              ["<C-Up>"] = actions.cycle_history_prev,
              -- page-scroll the RESULTS list (C-u/C-d scroll the preview)
              ["<M-d>"] = actions.results_scrolling_down,
              ["<M-u>"] = actions.results_scrolling_up,
            },
            n = {
              ["q"] = actions.close,
              ["<C-Down>"] = actions.cycle_history_next,
              ["<C-Up>"] = actions.cycle_history_prev,
              ["<M-d>"] = actions.results_scrolling_down,
              ["<M-u>"] = actions.results_scrolling_up,
            },
          },
        },
        extensions = {
          fzf = {},
          live_grep_args = {
            auto_quoting = true, -- quote the prompt so flags are passed to rg
            mappings = {
              i = {
                -- insert ' --iglob ' to add an include/exclude pattern, e.g.
                --   foo --iglob !**/test/**   or   foo --iglob *.lua
                -- quote_or_append: won't re-quote if the term is already quoted,
                -- so you can chain these without nesting the outer quotes.
                ["<C-g>"] = require("configs.lga_quote").quote_or_append { postfix = " --iglob " },
                -- insert ' --iglob !' to EXCLUDE files, then type the glob, e.g.
                --   foo --iglob !**/test/**   or   foo --iglob !build/**
                ["<M-g>"] = require("configs.lga_quote").quote_or_append { postfix = " --iglob !" },
                -- drop back to a plain fuzzy refine over the current results.
                -- NOTE: to_fuzzy_refine is a telescope *core* action, not an
                -- lga action. (<C-y>: unused by telescope's default insert maps.)
                ["<C-y>"] = actions.to_fuzzy_refine,
              },
            },
          },
        },
      }

      pcall(telescope.load_extension, "fzf")
      pcall(telescope.load_extension, "live_grep_args")
      -- smart_history needs sqlite.lua; guard so a missing lib never breaks config
      pcall(telescope.load_extension, "smart_history")

      -- remember last (even unsubmitted) prompt per picker, to restore on reopen
      require("configs.telescope_persist").setup()
    end,
  },
}
