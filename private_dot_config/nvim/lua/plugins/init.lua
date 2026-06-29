-- Core / UI / editing plugins. LSP, Telescope and DAP live in sibling files.
return {
  -- Common lua deps
  { "nvim-lua/plenary.nvim", lazy = true },
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- Theme ------------------------------------------------------------------
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000, -- load before everything so other plugins pick up colors
    config = function()
      require("catppuccin").setup {
        flavour = "mocha",
        transparent_background = false, -- matches old config (transparency = true)
        integrations = {
          telescope = true,
          which_key = true,
          gitsigns = true,
          treesitter = true,
          mason = true,
          dap = true,
          dap_ui = true,
          native_lsp = { enabled = true },
          cmp = true,
        },
      }
      vim.cmd.colorscheme "catppuccin"
    end,
  },

  -- Tmux-aware navigation (C-h/j/k/l move across vim splits AND tmux panes) --
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateRight",
      "TmuxNavigateUp",
      "TmuxNavigateDown",
    },
  },

  -- Sessions: :Obsession writes/updates a Session.vim that `nvim -S` restores --
  {
    "tpope/vim-obsession",
    lazy = false,
  },

  -- Cheat sheet + multi-key hints (replaces NvChad's cheatsheet/which-key) ---
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require "which-key"
      wk.setup {
        preset = "modern",
        delay = 300,
        spec = {
          { "<leader>f", group = "find (telescope)" },
          { "<leader>s", group = "search / session" },
          { "<leader>d", group = "debug" },
          { "<leader>t", group = "trouble" },
          { "<leader>c", group = "code" },
          { "<leader>u", group = "toggle / ui" },
          { "<leader>g", group = "git" },
          { "<leader>m", group = "molten / jupyter" },
        },
      }
      -- Full cheat sheet of every mapping
      vim.keymap.set("n", "<leader>?", function()
        wk.show { global = true }
      end, { desc = "Cheat sheet (all keymaps)" })
    end,
  },

  -- Statusline (NvChad provided one; lualine replaces it) -------------------
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        -- catppuccin ships per-flavour lualine themes (catppuccin-<flavour>);
        -- there is no plain "catppuccin" theme, so name the flavour explicitly.
        theme = "catppuccin-mocha",
        globalstatus = true,
        section_separators = "",
        component_separators = "|",
      },
      sections = {
        lualine_x = { "obsession", "encoding", "fileformat", "filetype" },
      },
    },
  },

  -- Git signs in the gutter -------------------------------------------------
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },

  -- Syntax / highlighting ---------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter.configs").setup {
        ensure_installed = {
          "c",
          "cpp",
          "lua",
          "vim",
          "vimdoc",
          "python",
          "go",
          "bash",
          "json",
          "markdown",
          "markdown_inline",
          "latex",
          "html",
          "yaml", -- render-markdown + math
        },
        auto_install = true,
        -- VimTeX owns .tex highlighting/conceal, so skip the treesitter latex
        -- highlighter there (render-markdown still uses the latex parser for math
        -- inside markdown).
        highlight = { enable = true, disable = { "latex" } },
        indent = { enable = true },
      }
      -- nvim-treesitter master branch ships query directives that are broken on
      -- Neovim 0.12 (array vs single-node match) and crash injection parsing
      -- (e.g. markdown code fences). Override them with compatible versions.
      pcall(require, "nvim-treesitter.query_predicates") -- ensure originals registered
      require("configs.treesitter_fix").apply()
    end,
  },

  -- Diagnostics list --------------------------------------------------------
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
    keys = {
      { "<leader>tx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>tX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics (Trouble)" },
    },
  },
}
