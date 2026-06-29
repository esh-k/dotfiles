-- Persist an open grug-far search across Obsession sessions.
--
-- Session.vim only serializes string/number globals (that's why the inputs are
-- JSON-encoded into a single global). We stash the live inputs into the
-- `GrugFarSession` global (saved via `sessionoptions+=globals`) and reopen
-- grug-far on SessionLoadPost. Closing the search clears the stored state.

local M = {}

local GLOBAL = "GrugFarSession"

local function get_inputs()
  local ok, grug = pcall(require, "grug-far")
  if not ok then
    return nil
  end
  local inst
  pcall(function()
    inst = grug.get_instance(0)
  end)
  if not inst then
    return nil
  end
  local state = inst.state or (inst.get_state and inst:get_state())
  if not state or not state.inputs then
    return nil
  end
  local i = state.inputs
  return {
    search = i.search,
    replacement = i.replacement,
    paths = i.paths,
    flags = i.flags,
    filesFilter = i.filesFilter,
  }
end

function M.save()
  local inputs = get_inputs()
  if inputs then
    vim.g[GLOBAL] = vim.json.encode(inputs)
  end
end

function M.clear()
  vim.g[GLOBAL] = nil
end

function M.restore()
  local raw = vim.g[GLOBAL]
  if not raw or raw == "" then
    return
  end
  local ok, inputs = pcall(vim.json.decode, raw)
  if not ok or type(inputs) ~= "table" then
    return
  end
  pcall(function()
    require("grug-far").open({ prefills = inputs })
  end)
end

function M.setup()
  local grp = vim.api.nvim_create_augroup("grug_far_session", { clear = true })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost", "BufLeave" }, {
    group = grp,
    callback = function()
      if vim.bo.filetype == "grug-far" then
        M.save()
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = grp,
    callback = function(ev)
      if vim.bo[ev.buf].filetype == "grug-far" then
        M.clear()
      end
    end,
  })

  vim.api.nvim_create_autocmd("SessionLoadPost", {
    group = grp,
    callback = function()
      vim.schedule(M.restore)
    end,
  })
end

return M
