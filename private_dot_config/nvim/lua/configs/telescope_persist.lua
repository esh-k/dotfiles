-- Restore the last *typed* prompt for find_files / live_grep_args, even if it
-- was never submitted (smart_history only records executed searches).
--
-- An `on_lines` watcher on the prompt buffer continuously stores the current
-- prompt keyed by picker title (mode-independent; TextChangedI is unreliable).
-- The keymaps below pass it back as `default_text`.

local M = {}

-- last prompt per picker title
M.last = {}

local FILES_TITLE = "Find Files"
local GREP_TITLE = "Live Grep (Args)"

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "TelescopePrompt",
    callback = function(ev)
      local bufnr = ev.buf
      vim.schedule(function()
        local ok, action_state = pcall(require, "telescope.actions.state")
        if not ok then
          return
        end
        local picker = action_state.get_current_picker(bufnr)
        if not picker then
          return
        end
        local title = picker.prompt_title
        vim.api.nvim_buf_attach(bufnr, false, {
          on_lines = function()
            if not vim.api.nvim_buf_is_valid(bufnr) then
              return true -- detach
            end
            local cur = action_state.get_current_line()
            if cur ~= nil then
              M.last[title] = cur
            end
          end,
        })
      end)
    end,
  })
end

function M.files()
  require("telescope.builtin").find_files({
    prompt_title = FILES_TITLE,
    default_text = M.last[FILES_TITLE] or "",
  })
end

function M.grep()
  require("telescope").extensions.live_grep_args.live_grep_args({
    prompt_title = GREP_TITLE,
    default_text = M.last[GREP_TITLE] or "",
  })
end

return M
