-- Remember the last prompt typed in a Telescope picker -- including text that
-- was never submitted -- so reopening the picker restores it instead of starting
-- blank. (smart_history only records *executed* searches; this fills the gap.)
--
-- The current prompt is captured continuously (on every keystroke) keyed by the
-- picker's title, so it survives any way the picker closes (<Esc>, select, etc.).
local M = { last = {} }

function M.setup()
  local grp = vim.api.nvim_create_augroup("TelescopePersistPrompt", { clear = true })
  -- When a prompt buffer is created, attach an on_lines watcher. on_lines fires
  -- on ANY text change regardless of mode (TextChangedI doesn't fire in all
  -- contexts), so the latest prompt is always captured by its picker title.
  vim.api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = "TelescopePrompt",
    callback = function(ev)
      vim.api.nvim_buf_attach(ev.buf, false, {
        on_lines = function()
          local ok, picker = pcall(require("telescope.actions.state").get_current_picker, ev.buf)
          if ok and type(picker) == "table" and picker.prompt_title then
            M.last[picker.prompt_title] = picker:_get_prompt()
          end
          -- returning falsy keeps the attachment alive
        end,
      })
    end,
  })
end

-- Reopen helpers that restore the last prompt as default_text.
function M.live_grep_args()
  require("telescope").extensions.live_grep_args.live_grep_args {
    default_text = M.last["Live Grep (Args)"] or "",
  }
end

function M.find_files()
  require("telescope.builtin").find_files {
    default_text = M.last["Find Files"] or "",
  }
end

return M
