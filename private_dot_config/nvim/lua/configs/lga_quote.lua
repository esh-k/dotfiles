-- live-grep-args helper: like its built-in quote_prompt, but if the prompt is
-- ALREADY quoted (begins with the quote char), it just appends the postfix
-- instead of wrapping/escaping the whole thing again. This lets you press
-- <C-g>/<M-g> repeatedly to chain multiple --iglob flags without breaking the
-- outermost quotes around the search term.
local M = {}

function M.quote_or_append(opts)
  opts = vim.tbl_extend("force", { quote_char = '"', postfix = " ", trim = true }, opts or {})
  return function(prompt_bufnr)
    local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
    local prompt = picker:_get_prompt()
    if opts.trim then
      prompt = vim.trim(prompt)
    end

    local new
    if prompt:sub(1, 1) == opts.quote_char then
      -- already quoted -> leave the outermost quotes, just add the flag
      new = prompt .. opts.postfix
    else
      -- not quoted yet -> wrap the term, then add the flag
      new = require("telescope-live-grep-args.helpers").quote(prompt, { quote_char = opts.quote_char }) .. opts.postfix
    end
    picker:set_prompt(new)
  end
end

return M
