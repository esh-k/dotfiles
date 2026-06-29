-- Helpers for molten-nvim: kernel discovery/registration, run-cell / run-all,
-- and buffer-local cell navigation. Cells are delimited by `# %%` (percent
-- format produced by jupytext).

local M = {}

local MARKER = [[^\s*# %%]]

-- ---- python / kernel discovery -------------------------------------------

local function executable(p)
  return p and vim.fn.executable(p) == 1
end

-- Resolve the project's python: activated venv -> walk-up .venv/venv/env -> PATH.
local function find_python()
  local env = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_PREFIX")
  if env and executable(env .. "/bin/python") then
    return env .. "/bin/python"
  end

  local dir = vim.fn.expand("%:p:h")
  local prev
  while dir ~= "" and dir ~= prev do
    for _, name in ipairs({ ".venv", "venv", "env" }) do
      local p = dir .. "/" .. name .. "/bin/python"
      if executable(p) then
        return p
      end
    end
    prev = dir
    dir = vim.fn.fnamemodify(dir, ":h")
  end

  if executable("python3") then
    return vim.fn.exepath("python3")
  end
  return nil
end

-- Detect the project python, register a kernelspec for it if none exists, then
-- start that kernel via MoltenInit. Needs ipykernel in the chosen env.
function M.init_kernel()
  local py = find_python()
  if not py then
    vim.notify("[molten] no python interpreter found", vim.log.levels.ERROR)
    return
  end
  py = vim.fn.resolve(py)

  vim.fn.system({ py, "-c", "import ipykernel" })
  if vim.v.shell_error ~= 0 then
    vim.notify(
      "[molten] ipykernel missing in " .. py .. "\nInstall it with:\n  " .. py .. " -m pip install ipykernel",
      vim.log.levels.ERROR
    )
    return
  end

  local name = "nvim-" .. vim.fn.sha256(py):sub(1, 8)
  local existing = vim.fn.system({ py, "-m", "jupyter", "kernelspec", "list" })
  if not existing:find(name, 1, true) then
    vim.fn.system({
      py, "-m", "ipykernel", "install", "--user",
      "--name", name,
      "--display-name", "nvim_test (" .. vim.fn.fnamemodify(py, ":~") .. ")",
    })
  end

  vim.cmd("MoltenInit " .. name)
end

-- ---- cell boundaries / running -------------------------------------------

local function is_marker(lnum)
  return vim.fn.getline(lnum):match("^%s*# %%%%") ~= nil
end

-- range [start, finish] of the cell the cursor is in (marker line .. line
-- before the next marker)
local function cell_bounds()
  local cur = vim.fn.line(".")
  local last = vim.fn.line("$")

  local start = cur
  while start > 1 and not is_marker(start) do
    start = start - 1
  end

  local finish = cur + 1
  while finish <= last and not is_marker(finish) do
    finish = finish + 1
  end
  finish = (finish <= last) and (finish - 1) or last

  return start, finish
end

function M.run_cell()
  local s, e = cell_bounds()
  -- NOTE: MoltenEvaluateRange is a vim *function*, not a command.
  vim.fn.MoltenEvaluateRange(s, e)
end

function M.run_cell_and_advance()
  M.run_cell()
  M.next_cell()
end

function M.run_all()
  local last = vim.fn.line("$")
  local markers = {}
  for l = 1, last do
    if is_marker(l) then
      markers[#markers + 1] = l
    end
  end
  if #markers == 0 then
    vim.fn.MoltenEvaluateRange(1, last)
    return
  end
  for idx, start in ipairs(markers) do
    local finish = markers[idx + 1] and (markers[idx + 1] - 1) or last
    vim.fn.MoltenEvaluateRange(start, finish)
  end
end

function M.next_cell()
  vim.fn.search(MARKER, "W")
end

function M.prev_cell()
  vim.fn.search(MARKER, "bW")
end

-- ---- buffer-local cell navigation ----------------------------------------

-- ]] / [[ jump to next/previous cell, but only in python/markdown buffers that
-- actually contain `# %%` markers (a plain .py keeps its default ]]/[[).
function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("molten_cell_nav", { clear = true }),
    pattern = { "python", "markdown" },
    callback = function(ev)
      local has_marker = false
      for _, line in ipairs(vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)) do
        if line:match("^%s*# %%%%") then
          has_marker = true
          break
        end
      end
      if not has_marker then
        return
      end
      vim.keymap.set("n", "]]", M.next_cell, { buffer = ev.buf, desc = "next cell (# %%)" })
      vim.keymap.set("n", "[[", M.prev_cell, { buffer = ev.buf, desc = "prev cell (# %%)" })
    end,
  })
end

return M
