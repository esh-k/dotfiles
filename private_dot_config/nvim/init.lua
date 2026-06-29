-- nvim_test — standalone config (no NvChad / starter framework).
-- Run with: NVIM_APPNAME=nvim_test nvim
-- Layout mirrors the old ~/.config/nvim: options / mappings / autocmds + lua/plugins/* + lua/configs/*

vim.g.mapleader = " "
-- localleader is also <space>: grug-far / coq / lean / vimtex buffer-local maps use <localleader>
vim.g.maplocalleader = " "

-- python3 provider lives in the molten venv (notebooks / molten remote plugin)
local molten_venv = vim.fn.stdpath("data") .. "/molten-venv"
if vim.fn.isdirectory(molten_venv) == 1 then
  vim.g.python3_host_prog = molten_venv .. "/bin/python"
end

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end
vim.opt.rtp:prepend(lazypath)

require "options"
require "autocmds"

local lazy_config = require "configs.lazy"
require("lazy").setup({ { import = "plugins" } }, lazy_config)

vim.schedule(function()
  require "mappings"
end)
