-- cspell_ls (Mason: cspell-lsp): code-aware spell check (splits camelCase /
-- snake_case) that runs out-of-process, replacing spelunker.vim which spell-checked
-- on the main thread and stalled the UI on big buffers.
--
-- Checking happens in the server process, so it never blocks editing. The only
-- main-thread cost is rendering the diagnostics it sends back, which is bounded by:
--   1. files > max_bytes never attach (checked in root_dir, before the server sees them)
--   2. max_problems caps diagnostics per file (~0.03ms each to render)
-- vim.b.cspell_disabled holds the reason it is off (<leader>uz turns it back on).

local M = {}

M.max_bytes = 1.5 * 1024 * 1024
M.max_problems = 1000
-- Zg adds words here instead of a cspell.json in whatever repo you're in
M.words_file = vim.fn.stdpath("config") .. "/spell/cspell-words.txt"

local NAME = "cspell_ls"
local markers = {
	".git",
	"cspell.json",
	".cspell.json",
	".cSpell.json",
	"cSpell.json",
	"cspell.config.js",
	"cspell.config.cjs",
	"cspell.config.json",
	"cspell.config.yaml",
	"cspell.config.yml",
	"cspell.yaml",
	"cspell.yml",
}

local function attached(bufnr)
	return #vim.lsp.get_clients({ bufnr = bufnr, name = NAME }) > 0
end

local function buf_bytes(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	local stat = name ~= "" and vim.uv.fs_stat(name)
	if stat then
		return stat.size
	end
	return vim.api.nvim_buf_get_offset(bufnr, vim.api.nvim_buf_line_count(bufnr))
end

function M.disable(bufnr, reason)
	vim.b[bufnr].cspell_disabled = reason
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = NAME })) do
		vim.lsp.buf_detach_client(bufnr, client.id)
		vim.diagnostic.reset(vim.lsp.diagnostic.get_namespace(client.id), bufnr)
	end
end

local function root_dir(bufnr, on_dir)
	if vim.bo[bufnr].buftype ~= "" or vim.b[bufnr].cspell_disabled then
		return
	end
	if buf_bytes(bufnr) > M.max_bytes then
		vim.b[bufnr].cspell_disabled = "too large"
		return
	end
	local fname = vim.api.nvim_buf_get_name(bufnr)
	on_dir(vim.fs.root(bufnr, markers) or (fname ~= "" and vim.fs.dirname(fname)) or vim.fn.getcwd())
end

-- ask only cspell for its code actions at the cursor: vim.lsp.buf.code_action waits
-- for every attached server, so a busy pyright/clangd would stall Zl/Zg
local function cspell_action(pred, apply)
	local bufnr = vim.api.nvim_get_current_buf()
	local client = vim.lsp.get_clients({ bufnr = bufnr, name = NAME })[1]
	if not client then
		return vim.notify("cspell: not attached", vim.log.levels.WARN)
	end
	local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
	local diags = vim.diagnostic.get(bufnr, { namespace = vim.lsp.diagnostic.get_namespace(client.id), lnum = lnum - 1 })
	diags = vim.tbl_filter(function(d)
		return d.col <= col and col < d.end_col
	end, diags)
	if #diags == 0 then
		return vim.notify("cspell: no misspelling under cursor")
	end
	local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
	params.context = { diagnostics = { diags[1].user_data.lsp } }
	client:request("textDocument/codeAction", params, function(err, actions)
		actions = vim.tbl_filter(pred, actions or {})
		if err or #actions == 0 then
			return vim.notify("cspell: no actions", vim.log.levels.WARN)
		end
		local function run(a)
			if a.edit then
				vim.lsp.util.apply_workspace_edit(a.edit, client.offset_encoding)
			end
			if a.command then
				client:exec_cmd(a.command, { bufnr = bufnr })
			end
		end
		if apply and #actions == 1 then
			return run(actions[1])
		end
		vim.ui.select(actions, {
			prompt = "cspell",
			format_item = function(a)
				return a.title
			end,
		}, function(a)
			if a then
				run(a)
			end
		end)
	end, bufnr)
end

function M.toggle(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if attached(bufnr) then
		M.disable(bufnr, "manual")
		vim.notify("cspell: off (buffer)")
		return
	end
	vim.b[bufnr].cspell_disabled = nil
	-- re-run vim.lsp.enable's attach logic (and so root_dir's size guard) for this buffer
	vim.api.nvim_exec_autocmds("FileType", { group = "nvim.lsp.enable", buffer = bufnr })
	local reason = vim.b[bufnr].cspell_disabled
	vim.notify("cspell: " .. (reason and ("not enabled (" .. reason .. ")") or "on (buffer)"))
end

function M.setup()
	if not vim.uv.fs_stat(M.words_file) then
		vim.fn.mkdir(vim.fs.dirname(M.words_file), "p")
		vim.fn.writefile({}, M.words_file)
	end

	vim.lsp.config(NAME, {
		root_dir = root_dir,
		-- the server asks to watch **/cspell.json across the whole root; skip that
		-- (it's only used to notice config edits, which a restart also picks up)
		capabilities = { workspace = { didChangeWatchedFiles = { dynamicRegistration = false } } },
		init_options = {
			defaultSettings = {
				dictionaryDefinitions = { { name = "nvim-user", path = M.words_file, addWords = true } },
				dictionaries = { "nvim-user" },
				maxNumberOfProblems = M.max_problems,
			},
		},
	})

	local map = vim.keymap.set
	-- Z-prefixed (only ZZ/ZQ are native, so these are collision-free)
	map("n", "Zl", function()
		cspell_action(function(a)
			return a.edit ~= nil
		end)
	end, { desc = "spell: correct word under cursor" })
	map("n", "Zg", function()
		cspell_action(function(a)
			return a.command ~= nil and a.command.command == "AddToCustomDictionary"
		end, true)
	end, { desc = "spell: add word to dictionary" })
	-- toggle in the <leader>u (ui/toggle) namespace, alongside uf/um/up
	map("n", "<leader>uz", function()
		M.toggle()
	end, { desc = "spell: toggle cspell (buffer)" })
end

return M
