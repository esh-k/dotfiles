-- lazy.nvim setup: import every spec under lua/plugins/ plus global options.
return {
  spec = {
    { import = "plugins" },
  },
  defaults = { lazy = false },
  install = { colorscheme = { "catppuccin" } },
  change_detection = { notify = false },
  ui = { border = "rounded" },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
        -- NB: do NOT disable netrwPlugin here -- nvim-tree hijacks netrw's
        -- FileExplorer autocmd, which errors (E216) if netrw never loaded.
      },
    },
  },
}
