-- Browsable "window" over the persisted Telescope history (all picker types).
--
-- telescope-smart-history only provides a history *backend* (cycled with
-- <C-Up>/<C-Down> inside a prompt) -- it has no picker to view the list. This
-- module reads the same sqlite DB and presents every past search in a Telescope
-- window you can fuzzy-filter; selecting one re-runs it in the right picker.
local M = {}

local DB = vim.fn.stdpath "data" .. "/telescope_history.sqlite3"

-- smart_history stores content wrapped as __ESCAPED__'<content>'
local function unescape(s)
  return (s:gsub("^__ESCAPED__'(.*)'$", "%1"))
end

-- Short, friendly label shown in the type column.
local function kind(title)
  local t = (title or ""):lower()
  if t:find "grep" then return "grep" end
  if t:find "old" or t:find "recent" then return "recent" end
  if t:find "file" then return "files" end
  if t:find "buffer" then return "buffers" end
  if t:find "help" then return "help" end
  if t:find "key" then return "keymaps" end
  if t:find "diagnostic" then return "diag" end
  if t:find "mark" then return "marks" end
  return (title or "?"):lower()
end

-- Re-open the picker a history entry came from, pre-filled with its query.
local function rerun(title, query)
  local t = (title or ""):lower()
  local tb = require "telescope.builtin"
  if t:find "grep" then
    require("telescope").extensions.live_grep_args.live_grep_args { default_text = query }
  elseif t:find "old" or t:find "recent" then
    tb.oldfiles { default_text = query }
  elseif t:find "file" then
    tb.find_files { default_text = query }
  elseif t:find "buffer" then
    tb.buffers { default_text = query }
  elseif t:find "help" then
    tb.help_tags { default_text = query }
  elseif t:find "key" then
    tb.keymaps { default_text = query }
  elseif t:find "diagnostic" then
    tb.diagnostics { default_text = query }
  elseif t:find "mark" then
    tb.marks { default_text = query }
  else
    -- unknown picker type: most useful generic fallback is a content grep
    require("telescope").extensions.live_grep_args.live_grep_args { default_text = query }
  end
end

function M.history()
  local ok, sqlite = pcall(require, "sqlite")
  if not ok then
    vim.notify("sqlite.lua not available; search history needs it.", vim.log.levels.WARN)
    return
  end
  if vim.fn.filereadable(DB) == 0 then
    vim.notify("No search history yet -- use a Telescope picker and select a result first.", vim.log.levels.INFO)
    return
  end

  local db = sqlite.new(DB)
  db:open()
  local rows = db:eval "select content, picker from history"
  db:close()

  -- eval returns `true` when there are no rows, or a single row table when 1.
  if type(rows) ~= "table" then
    rows = {}
  elseif rows.content ~= nil then
    rows = { rows }
  end

  -- newest first, de-duplicated on (picker + query)
  local seen, items = {}, {}
  for i = #rows, 1, -1 do
    local query = unescape(rows[i].content)
    local title = rows[i].picker or ""
    local key = title .. "\0" .. query
    if query ~= "" and not seen[key] then
      seen[key] = true
      items[#items + 1] = { title = title, query = query, kind = kind(title) }
    end
  end

  if #items == 0 then
    vim.notify("No search history yet.", vim.log.levels.INFO)
    return
  end

  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local astate = require "telescope.actions.state"
  local entry_display = require "telescope.pickers.entry_display"

  local displayer = entry_display.create {
    separator = "  ",
    items = {
      { width = 9 }, -- kind column (grep / files / buffers / ...)
      { remaining = true }, -- the query
    },
  }

  local make_display = function(entry)
    return displayer {
      { entry.value.kind, "TelescopeResultsComment" },
      entry.value.query,
    }
  end

  pickers
    .new({}, {
      prompt_title = "Search History — <CR> to re-run",
      finder = finders.new_table {
        results = items,
        entry_maker = function(item)
          return {
            value = item,
            display = make_display,
            ordinal = item.kind .. " " .. item.query, -- fuzzy match type + query
          }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(bufnr)
        actions.select_default:replace(function()
          local entry = astate.get_selected_entry()
          actions.close(bufnr)
          if entry and entry.value then
            rerun(entry.value.title, entry.value.query)
          end
        end)
        return true
      end,
    })
    :find()
end

-- Backwards-compatible alias.
M.grep_history = M.history

return M
