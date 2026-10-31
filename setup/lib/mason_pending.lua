-- Print the mason-tool-installer packages that aren't installed yet, one per line.
local plugin = require("lazy.core.config").plugins["mason-tool-installer.nvim"]
local opts = require("lazy.core.plugin").values(plugin, "opts", false)
local registry = require("mason-registry")
registry.refresh()
for _, name in ipairs(opts.ensure_installed or {}) do
	name = type(name) == "table" and name[1] or name
	local ok, pkg = pcall(registry.get_package, name)
	if ok and not pkg:is_installed() then
		io.stdout:write(name .. "\n")
	end
end
