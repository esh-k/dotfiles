-- Persist an open grug-far search across a saved vim session (Obsession).
--
-- grug-far already persists *history* to disk (stdpath('state')/grug-far, browse
-- with <localleader>t). What it lacks is restoring the CURRENTLY-open search when
-- a session is reloaded. We serialize the live inputs into a global that mksession
-- saves (sessionoptions+=globals; the var name starts uppercase + has lowercase,
-- as `:h sessionoptions` requires) and reopen grug-far on SessionLoadPost.
local M = {}

-- mksession only stores globals starting with uppercase and containing lowercase.
local GVAR = "GrugFarSession"

local INPUT_KEYS = { "search", "replacement", "filesFilter", "flags", "paths" }

-- Read the live inputs of the (first) open grug-far buffer, or nil if none.
local function current_inputs()
  local ok_inst, instances = pcall(require, "grug-far.instances")
  local ok_in, inputs = pcall(require, "grug-far.inputs")
  if not (ok_inst and ok_in) then
    return nil
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "grug-far" then
      local got, inst = pcall(instances.get_instance_by_buf, buf)
      if got and inst and inst._context then
        -- getValues reads extmarks that may not exist until the instance is
        -- ready; guard so an early call can't error.
        local ok, vals = pcall(inputs.getValues, inst._context, buf)
        if ok and vals and vals.search and vals.search ~= "" then
          local out = {}
          for _, k in ipairs(INPUT_KEYS) do
            out[k] = vals[k]
          end
          return out
        end
      end
    end
  end
  return nil
end

local function save()
  local vals = current_inputs()
  -- vim.g can't hold nil to "delete"; "" means "nothing to restore"
  vim.g[GVAR] = vals and vim.json.encode(vals) or ""
end

function M.restore()
  -- mksession may re-create a stale grug-far buffer that isn't a real instance;
  -- wipe those so we don't leave a broken buffer lying around.
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(buf):match "grug%-far" then
      local ok, inst = pcall(require("grug-far.instances").get_instance_by_buf, buf)
      if not (ok and inst) then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  end

  local raw = vim.g[GVAR]
  if type(raw) ~= "string" or raw == "" then
    return
  end
  local ok, vals = pcall(vim.json.decode, raw)
  if not ok or type(vals) ~= "table" or not vals.search then
    return
  end
  require("grug-far").open { prefills = vals }
end

function M.setup()
  local grp = vim.api.nvim_create_augroup("GrugFarSession", { clear = true })

  -- Keep the session global in sync with the live grug-far inputs.
  vim.api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = "grug-far",
    callback = function(ev)
      vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave", "BufWinLeave" }, {
        buffer = ev.buf,
        group = grp,
        callback = function()
          vim.schedule(save)
        end,
      })
      -- capture once the instance has finished initializing its inputs
      local ok, inst = pcall(require("grug-far.instances").get_instance_by_buf, ev.buf)
      if ok and inst and inst.when_ready then
        inst:when_ready(function()
          vim.schedule(save)
        end)
      else
        vim.schedule(save)
      end
    end,
  })

  -- When the grug-far buffer is gone, drop the stored state (so a closed search
  -- isn't reopened on the next session load).
  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
    group = grp,
    callback = function(ev)
      if vim.bo[ev.buf].filetype == "grug-far" then
        vim.schedule(save)
      end
    end,
  })

  -- Reopen the saved search after a session is restored.
  vim.api.nvim_create_autocmd("SessionLoadPost", {
    group = grp,
    callback = function()
      vim.schedule(M.restore)
    end,
  })
end

return M
