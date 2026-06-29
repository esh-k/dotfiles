-- Helpers for running Jupyter cells with molten-nvim. Cells are delimited by
-- jupytext "percent" markers (`# %%`), so "run cell" means evaluate the lines
-- between the surrounding markers.
local M = {}

local function is_marker(line)
  -- matches `# %%`, `# %% [markdown]`, `#%%`, etc.  (Lua pattern)
  return line ~= nil and line:match "^#%s*%%%%" ~= nil
end

-- Same matcher as a VIM regex, for vim.fn.search().
local CELL_RE = [[^#\s*%%]]

-- Return the 1-indexed [start, end] line range of the cell the cursor is in
-- (excluding the marker line itself).
local function cell_bounds()
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local last = vim.api.nvim_buf_line_count(0)

  local s = cur
  while s >= 1 do
    local line = vim.api.nvim_buf_get_lines(0, s - 1, s, false)[1]
    if is_marker(line) then
      break
    end
    s = s - 1
  end
  local start_line = math.max(1, s + 1) -- first line after the marker (or BOF)

  local e = cur + 1
  while e <= last do
    local line = vim.api.nvim_buf_get_lines(0, e - 1, e, false)[1]
    if is_marker(line) then
      break
    end
    e = e + 1
  end
  local end_line = math.min(last, e - 1)

  if end_line < start_line then
    end_line = start_line
  end
  return start_line, end_line
end

-- Evaluate the current cell. MoltenEvaluateRange is a vim *function*
-- (MoltenEvaluateRange(start_line, end_line)), not a command.
function M.run_cell()
  local s, e = cell_bounds()
  vim.fn.MoltenEvaluateRange(s, e)
end

-- Jump to the next / previous cell marker (`# %%`).
function M.next_cell()
  if vim.fn.search(CELL_RE, "W") == 0 then
    vim.cmd "normal! G"
  end
end

function M.prev_cell()
  vim.fn.search(CELL_RE, "bW")
end

-- Evaluate the current cell, then jump to the next cell.
function M.run_cell_and_advance()
  M.run_cell()
  M.next_cell()
end

-- Evaluate every cell in the buffer, top to bottom.
function M.run_all()
  local last = vim.api.nvim_buf_line_count(0)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- collect marker line numbers (1-indexed)
  local markers = {}
  for i, l in ipairs(lines) do
    if is_marker(l) then
      markers[#markers + 1] = i
    end
  end
  -- build cell ranges
  if #markers == 0 then
    vim.fn.MoltenEvaluateRange(1, last)
    return
  end
  for idx, m in ipairs(markers) do
    local s = m + 1
    local e = (markers[idx + 1] and markers[idx + 1] - 1) or last
    if e >= s then
      vim.fn.MoltenEvaluateRange(s, e)
    end
  end
end

-- ---------------------------------------------------------------------------
-- Kernel selection that follows your project's Python environment.
--
-- molten only lists *registered* Jupyter kernelspecs, so a bare venv / pyenv
-- python won't appear in its picker (you'd only see python3 + nvim_test). The
-- functions below detect the project's interpreter, make sure a kernelspec for
-- it exists (registering one on the fly if needed), then start that kernel.
-- ---------------------------------------------------------------------------

local function executable(p)
  return p and p ~= "" and vim.fn.executable(p) == 1
end

-- Resolve the Python interpreter for the current project, in priority order.
local function find_project_python()
  -- 1. activated venv / conda env
  for _, var in ipairs { "VIRTUAL_ENV", "CONDA_PREFIX" } do
    local root = vim.env[var]
    if root and root ~= "" and executable(root .. "/bin/python") then
      return root .. "/bin/python"
    end
  end
  -- 2. a venv directory in the project (search up from the current file)
  local start = vim.api.nvim_buf_get_name(0)
  if start == "" then
    start = vim.fn.getcwd()
  end
  local root = vim.fs.root(start, { ".venv", "venv", "env", ".git", "pyproject.toml", ".python-version" })
    or vim.fn.getcwd()
  for _, name in ipairs { ".venv", "venv", "env", ".env" } do
    if executable(root .. "/" .. name .. "/bin/python") then
      return root .. "/" .. name .. "/bin/python"
    end
  end
  -- 3. pyenv / PATH python3 (the shim respects .python-version in the project)
  local py = vim.fn.exepath "python3"
  if py ~= "" then
    return py
  end
  return nil
end

-- Resolve to the real interpreter path (sys.executable), so pyenv shims and
-- symlinks map to a stable kernelspec.
local function canonical_python(py)
  local real = vim.trim(vim.fn.system { py, "-c", "import sys; print(sys.executable)" })
  if vim.v.shell_error == 0 and real ~= "" then
    return real
  end
  return py
end

local function has_ipykernel(py)
  vim.fn.system { py, "-c", "import ipykernel" }
  return vim.v.shell_error == 0
end

local function jupyter_bin()
  return vim.fn.stdpath "data" .. "/molten-venv/bin/jupyter"
end

-- Name a kernel after its env directory: .../<env>/bin/python -> <env>.
-- For generically-named venv dirs (.venv/venv/...), use the project dir instead
-- so the kernel is recognizable (e.g. /proj/.venv -> "proj").
local function kernel_name_for(py)
  local envdir = vim.fn.fnamemodify(py, ":h:h")
  local base = vim.fn.fnamemodify(envdir, ":t")
  local generic = { [".venv"] = true, ["venv"] = true, ["env"] = true, [".env"] = true }
  if generic[base] then
    local proj = vim.fn.fnamemodify(envdir, ":h:t")
    if proj and proj ~= "" and proj ~= "." then
      base = proj
    end
  end
  if base == "" or base == "." or base == "/" then
    base = "python"
  end
  return "nvim-" .. base, base
end

-- Ensure a kernelspec exists for `py`; (re)register it if missing/stale.
-- Returns the kernel name, or nil + error message.
local function ensure_kernelspec(py)
  local kname, display = kernel_name_for(py)
  local jup = jupyter_bin()
  if executable(jup) then
    local out = vim.fn.system { jup, "kernelspec", "list", "--json" }
    local ok, data = pcall(vim.json.decode, out)
    if ok and data and data.kernelspecs and data.kernelspecs[kname] then
      local argv = data.kernelspecs[kname].spec and data.kernelspecs[kname].spec.argv
      if argv and vim.fs.normalize(argv[1] or "") == vim.fs.normalize(py) then
        return kname -- already registered and current
      end
    end
  end
  -- (re)register; writes to the user Jupyter dir, discoverable by molten
  vim.fn.system {
    py, "-m", "ipykernel", "install", "--user",
    "--name", kname, "--display-name", "Python (" .. display .. ")",
  }
  if vim.v.shell_error ~= 0 then
    return nil, "failed to register kernelspec for " .. py
  end
  return kname
end

-- Start a kernel for the project's environment. Falls back to molten's picker
-- if no interpreter is found, and tells you what to do if ipykernel is missing.
function M.init_kernel()
  local py = find_project_python()
  if not py then
    vim.cmd "MoltenInit" -- nothing detected: interactive picker
    return
  end
  py = canonical_python(py)

  if not has_ipykernel(py) then
    vim.notify(
      ("Molten: %s has no ipykernel. Install it with:\n  %s -m pip install ipykernel\nFalling back to picker.")
        :format(py, py),
      vim.log.levels.WARN
    )
    vim.cmd "MoltenInit"
    return
  end

  local kname, err = ensure_kernelspec(py)
  if not kname then
    vim.notify("Molten: " .. (err or "could not prepare kernel") .. "; using picker.", vim.log.levels.WARN)
    vim.cmd "MoltenInit"
    return
  end

  vim.cmd("MoltenInit " .. kname)
  vim.notify(("Molten: kernel '%s'  ->  %s"):format(kname, py), vim.log.levels.INFO)
end

-- Always show molten's picker (manual override).
function M.pick_kernel()
  vim.cmd "MoltenInit"
end

return M
