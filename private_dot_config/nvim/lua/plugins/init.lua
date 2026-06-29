return {
	-- Theme: catppuccin (mocha) with transparency, matching the old chadrc.
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false,
		priority = 1000,
		opts = {
			flavour = "mocha",
			transparent_background = false,
			integrations = {
				gitsigns = true,
				treesitter = true,
				nvimtree = true,
				telescope = true,
				which_key = true,
				mason = true,
				dap = true,
				dap_ui = true,
				blink_cmp = true,
				native_lsp = { enabled = true },
			},
		},
		config = function(_, opts)
			require("catppuccin").setup(opts)
			vim.cmd.colorscheme("catppuccin")
		end,
	},

	-- Tmux-aware navigation (paired with the <C-hjkl> maps in mappings.lua)
	{ "christoomey/vim-tmux-navigator", lazy = false },

	-- Session save/restore. lazy = false so `nvim -S Session.vim` works.
	{ "tpope/vim-obsession", lazy = false },

	-- Cheat sheet / multi-key hint popups
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "modern",
			spec = {
				{ "<leader>c", group = "code" },
				{ "<leader>f", group = "find (telescope)" },
				{ "<leader>s", group = "search / replace / history" },
				{ "<leader>m", group = "molten / markdown" },
				{ "<leader>d", group = "debug" },
				{ "<leader>u", group = "toggles" },
				{ "<leader>t", group = "trouble" },
			},
		},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = true })
				end,
				desc = "Cheat sheet (all keybindings)",
			},
		},
	},

	-- Statusline (shows Obsession status)
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			options = {
				theme = "catppuccin-mocha",
				globalstatus = true,
			},
			sections = {
				lualine_x = { "ObsessionStatus", "encoding", "fileformat", "filetype" },
			},
		},
	},

	-- Git signs
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {},
	},

	-- Treesitter (frozen master branch + 0.12 compat shim)
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		build = ":TSUpdate",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			ensure_installed = {
				"lua",
				"vim",
				"vimdoc",
				"c",
				"cpp",
				"go",
				"python",
				"bash",
				"json",
				"yaml",
				"markdown",
				"markdown_inline",
				"latex",
				"html",
			},
			highlight = {
				enable = true,
				-- VimTeX owns .tex highlighting/conceal
				disable = { "latex" },
			},
			indent = { enable = true },
		},
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)
			require("configs.treesitter_fix")
		end,
	},

	-- File tree with horizontal scrolling for overflowing names
	{
		"nvim-tree/nvim-tree.lua",
		cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },
		dependencies = { "nvim-tree/nvim-web-devicons" },
		keys = {
			{ "<C-n>", "<cmd>NvimTreeToggle<CR>", desc = "toggle file tree" },
			{ "<leader>e", "<cmd>NvimTreeFocus<CR>", desc = "focus file tree" },
		},
		config = function()
			require("nvim-tree").setup({
				view = { preserve_window_proportions = true },
				on_attach = function(bufnr)
					local api = require("nvim-tree.api")
					api.config.mappings.default_on_attach(bufnr)

					local function o(desc)
						return {
							desc = "nvim-tree: " .. desc,
							buffer = bufnr,
							noremap = true,
							silent = true,
							nowait = true,
						}
					end
					-- h/l are unused by nvim-tree defaults; use them to scroll horizontally
					-- so long file names hidden to the right become visible. (arrows / <C-arrows>
					-- avoided since terminals/tmux often intercept them.)
					vim.keymap.set("n", "l", "zL", o("scroll right (half width)"))
					vim.keymap.set("n", "h", "zH", o("scroll left (half width)"))
					vim.keymap.set("n", "<End>", "150zl", o("scroll to end of name"))
					vim.keymap.set("n", "<Home>", "150zh", o("scroll to start of name"))

					-- nvim-tree overwrites window opts post-attach, so set them deferred.
					-- virtualedit=all is REQUIRED: otherwise zl/zh refuse to scroll while
					-- the cursor sits on a short entry (Vim keeps the cursor on screen).
					vim.schedule(function()
						vim.wo.wrap = false
						vim.wo.sidescrolloff = 0
						vim.wo.virtualedit = "all"
					end)
				end,
			})
		end,
	},

	-- Diagnostics / quickfix viewer
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		opts = {},
		keys = {
			{ "<leader>tx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
			{ "<leader>tX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
			{
				"<leader>tcl",
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				desc = "LSP refs (Trouble)",
			},
			{ "<leader>txQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix (Trouble)" },
			{ "<leader>txL", "<cmd>Trouble loclist toggle<cr>", desc = "Loclist (Trouble)" },
		},
	},
}
