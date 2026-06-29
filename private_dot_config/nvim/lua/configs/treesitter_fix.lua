-- Treesitter 0.12 compat shim.
--
-- nvim-treesitter's frozen `master` branch ships query directives that assume
-- `match[id]` is a single TSNode, but Neovim 0.12 passes an array of nodes.
-- That mismatch crashed injection parsing and flooded any markdown file
-- containing fenced code blocks with
--   `treesitter.lua: attempt to call method 'range' (a nil value)`
-- making them uneditable.
--
-- Re-register the affected directives (`set-lang-from-info-string!`,
-- `set-lang-from-mimetype!`, `downcase!`) with array-safe handlers. Applied
-- right after the treesitter setup (see plugins/init.lua).

local add_directive = vim.treesitter.query.add_directive
local get_node_text = vim.treesitter.get_node_text

-- Normalize match[id] to a single node, tolerating both the old (single node)
-- and 0.12 (array of nodes) shapes.
local function node_for(match, id)
  local n = match[id]
  if type(n) == "table" then
    return n[#n]
  end
  return n
end

-- ft/alias -> parser language. Prefer nvim-treesitter's own table if present.
local ok_parsers, parsers = pcall(require, "nvim-treesitter.parsers")
local function lang_from_string(s)
  if not s or s == "" then
    return nil
  end
  s = s:lower():match("^%s*([%w_%-%+%.#]*)") or s
  if ok_parsers then
    if type(parsers.ft_to_lang) == "function" then
      local ok, lang = pcall(parsers.ft_to_lang, s)
      if ok and lang then
        return lang
      end
    end
    if type(parsers.ft_to_lang) == "table" and parsers.ft_to_lang[s] then
      return parsers.ft_to_lang[s]
    end
  end
  return s
end

add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
  local node = node_for(match, pred[2])
  if not node then
    return
  end
  local ok, text = pcall(get_node_text, node, bufnr)
  if ok and text then
    metadata["injection.language"] = lang_from_string(text)
  end
end, { force = true, all = true })

add_directive("set-lang-from-mimetype!", function(match, _, bufnr, pred, metadata)
  local node = node_for(match, pred[2])
  if not node then
    return
  end
  local ok, text = pcall(get_node_text, node, bufnr)
  if ok and text then
    -- e.g. "text/x-python" -> "python"
    local mapped = text:gsub("^.*[/%-]", "")
    metadata["injection.language"] = lang_from_string(mapped)
  end
end, { force = true, all = true })

add_directive("downcase!", function(match, _, bufnr, pred, metadata)
  local node = node_for(match, pred[2])
  if not node then
    return
  end
  local key = pred[3] or "text"
  local ok, text = pcall(get_node_text, node, bufnr)
  if ok and text then
    metadata[key] = text:lower()
  end
end, { force = true, all = true })
