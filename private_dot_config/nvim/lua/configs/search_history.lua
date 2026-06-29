-- A browsable/fuzzy-searchable picker over ALL past Telescope searches.
--
-- telescope-smart-history ships only a sqlite *backend* (no picker of its own),
-- so this reads the same DB (stdpath('data')/telescope_history.sqlite3) and
-- builds a picker. Each row shows a type tag + the query; <CR> re-runs it in the
-- matching picker (grep -> live_grep_args, files -> find_files, ...).
--
-- NOTE: smart_history holds its sqlite connection open, so a search made in the
-- *current* session shows up here only after a restart; use <C-Up>/<C-Down> in a
-- prompt to recall same-session searches.

local M = {}

local function db_path()
  return vim.fn.stdpath("data") .. "/telescope_history.sqlite3"
end

-- map a stored picker tag to a runnable picker
local function rerun(tag, query)
  tag = (tag or ""):lower()
  local builtin = require("telescope.builtin")
  if tag:find("grep") then
    require("telescope").extensions.live_grep_args.live_grep_args({ default_text = query })
  elseif tag:find("file") then
    builtin.find_files({ default_text = query })
  elseif tag:find("buffer") then
    builtin.buffers({ default_text = query })
  elseif tag:find("help") then
    builtin.help_tags({ default_text = query })
  elseif tag:find("oldfile") then
    builtin.oldfiles({ default_text = query })
  elseif tag:find("keymap") then
    builtin.keymaps({ default_text = query })
  else
    require("telescope").extensions.live_grep_args.live_grep_args({ default_text = query })
  end
end

-- read rows defensively: the smart_history schema stores a query column and a
-- picker column, but column names have varied across versions, so detect them.
local function read_rows()
  local ok, sqlite = pcall(require, "sqlite")
  if not ok then
    vim.notify("[search_history] sqlite.lua not available", vim.log.levels.ERROR)
    return nil
  end
  local path = db_path()
  if vim.fn.filereadable(path) == 0 then
    vim.notify("[search_history] no history DB yet: " .. path, vim.log.levels.WARN)
    return {}
  end

  local db = sqlite({ uri = path })
  local raw
  pcall(function()
    raw = db:eval("select * from history order by id desc")
  end)
  pcall(function()
    db:close()
  end)
  if type(raw) ~= "table" then
    return {}
  end

  local rows = {}
  for _, r in ipairs(raw) do
    local query = r.query or r.cmd or r.prompt or r.line
    local tag = r.picker or r.type or r.kind or "grep"
    if type(query) == "string" and query ~= "" then
      rows[#rows + 1] = { query = query, tag = tostring(tag) }
    end
  end
  return rows
end

function M.open()
  local rows = read_rows()
  if not rows then
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local entry_display = require("telescope.pickers.entry_display")

  local displayer = entry_display.create({
    separator = " ",
    items = { { width = 12 }, { remaining = true } },
  })

  pickers
    .new({}, {
      prompt_title = "Telescope Search History",
      finder = finders.new_table({
        results = rows,
        entry_maker = function(row)
          return {
            value = row,
            ordinal = row.tag .. " " .. row.query,
            display = function(e)
              return displayer({ { "[" .. e.value.tag .. "]", "TelescopeResultsComment" }, e.value.query })
            end,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if entry and entry.value then
            rerun(entry.value.tag, entry.value.query)
          end
        end)
        return true
      end,
    })
    :find()
end

return M
