return {
  defaults = { lazy = true },
  install = { colorscheme = { "catppuccin" } },

  ui = {
    icons = {
      ft = "",
      lazy = "󰂠 ",
      loaded = "",
      not_loaded = "",
    },
  },

  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
        -- IMPORTANT: do NOT disable "netrwPlugin" — nvim-tree hijacks netrw's
        -- FileExplorer autocmd and throws E216 into v:errmsg if netrw never loaded.
      },
    },
  },
}
