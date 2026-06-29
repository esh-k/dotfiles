-- Compatibility shim for nvim-treesitter's (frozen) `master` branch on Neovim
-- 0.12+. Several of its query directives assume `match[id]` is a single TSNode,
-- but Neovim 0.12 passes an array of nodes to directive handlers. The mismatch
-- crashes injection parsing -- e.g. opening a markdown file with a fenced code
-- block floods the screen with:
--   treesitter.lua: attempt to call method 'range' (a nil value)
--      ... query_predicates.lua ... _get_injections ...
-- We re-register the affected directives (force) with array-safe handlers.
local M = {}

local query = vim.treesitter.query

-- normalize match[id] to a single node (0.12 may hand us an array)
local function one(node)
  if type(node) == "table" then
    return node[#node]
  end
  return node
end

function M.apply()
  -- markdown fenced code blocks: ```go etc. -> injection language
  query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
    local node = one(match[pred[2]])
    if not node then
      return
    end
    local alias = vim.treesitter.get_node_text(node, bufnr):lower()
    metadata["injection.language"] = vim.treesitter.language.get_lang(alias) or alias
  end, { force = true, all = false })

  -- html <script type="..."> -> injection language
  query.add_directive("set-lang-from-mimetype!", function(match, _, bufnr, pred, metadata)
    local node = one(match[pred[2]])
    if not node then
      return
    end
    local value = vim.treesitter.get_node_text(node, bufnr)
    local parts = vim.split(value, "/", {})
    local lang = parts[#parts]
    metadata["injection.language"] = vim.treesitter.language.get_lang(lang) or lang
  end, { force = true, all = false })

  -- case-insensitive injection language
  query.add_directive("downcase!", function(match, _, bufnr, pred, metadata)
    local id = pred[2]
    local node = one(match[id])
    if not node then
      return
    end
    local text = vim.treesitter.get_node_text(node, bufnr, { metadata = metadata[id] }) or ""
    if not metadata[id] then
      metadata[id] = {}
    end
    metadata[id].text = string.lower(text)
  end, { force = true, all = false })
end

return M
