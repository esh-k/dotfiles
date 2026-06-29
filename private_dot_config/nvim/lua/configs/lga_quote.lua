-- Helper for telescope-live-grep-args: quote the search term (if not already
-- quoted) and append a ripgrep flag, so <C-g> / <M-g> chain on one prompt line
-- without nesting quotes.
--
--   <C-g>  ->  append ` --iglob `   (include glob)
--   <M-g>  ->  append ` --iglob !`  (exclude glob)
--
-- If the term is already quoted we only append the flag (no re-quoting).

local M = {}

function M.quote_or_append(postfix)
  return function(prompt_bufnr)
    local action_state = require("telescope.actions.state")
    local line = action_state.get_current_line() or ""

    if line:match('"[^"]*"') then
      -- already quoted: just append the flag text
      local picker = action_state.get_current_picker(prompt_bufnr)
      picker:set_prompt(line .. postfix)
    else
      local lga_actions = require("telescope-live-grep-args.actions")
      lga_actions.quote_prompt({ postfix = postfix })(prompt_bufnr)
    end
  end
end

return M
