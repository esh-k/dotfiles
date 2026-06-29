-- Entry point. Loosely mirrors the layout of the old NvChad-based config
-- (options / mappings / autocmds + lua/plugins + lua/configs) but is fully
-- standalone -- no starter framework.

-- Leader must be set before lazy + plugins load so mappings register correctly.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Point the python3 provider at the dedicated molten venv (pynvim/jupyter_client/
-- ipykernel live there, not in Mason). Guarded so a missing venv can't break the
-- provider. Recreate with:
--   python3 -m venv ~/.local/share/nvim_test/molten-venv
--   ~/.local/share/nvim_test/molten-venv/bin/pip install pynvim jupyter_client ipykernel
local molten_py = vim.fn.stdpath "data" .. "/molten-venv/bin/python"
if vim.fn.filereadable(molten_py) == 1 then
  vim.g.python3_host_prog = molten_py
end

require "options"

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup(require "configs.lazy")

require "autocmds"

-- Mappings that don't belong to a specific plugin spec. Scheduled so they run
-- after startup (lets plugin-provided maps land first if needed).
vim.schedule(function()
  require "mappings"
end)
