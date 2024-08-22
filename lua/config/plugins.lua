return {
	-- manage itself
	"folke/lazy.nvim",
	"neovim/nvim-lspconfig",
	{
		"Pocco81/auto-save.nvim",
		config = function()
			require("plugins.autosave")
		end,
	},

	{
		"antosha417/nvim-lsp-file-operations",
		event = "LspAttach",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-tree.lua",
		},
		--config = function()
		--require("lsp-file-operations").setup()
		--end,
	},

	-- quick move
	{
		"folke/trouble.nvim",
		opts = {}, -- for default options, refer to the configuration section for custom setup.
		cmd = "Trouble",
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
			{
				"<leader>xX",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Buffer Diagnostics (Trouble)",
			},
			{
				"<leader>cs",
				"<cmd>Trouble symbols toggle focus=false<cr>",
				desc = "Symbols (Trouble)",
			},
			{
				"<leader>cl",
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				desc = "LSP Definitions / references / ... (Trouble)",
			},
			{
				"<leader>xL",
				"<cmd>Trouble loclist toggle<cr>",
				desc = "Location List (Trouble)",
			},
			{
				"<leader>xQ",
				"<cmd>Trouble qflist toggle<cr>",
				desc = "Quickfix List (Trouble)",
			},
		},
	},
	{
		"ggandor/leap.nvim",
		config = function()
			require("leap").add_default_mappings()
		end,
	},
	{
		"ggandor/flit.nvim",
		config = function()
			require("flit").setup({
				keys = { f = "f", F = "F", t = "t", T = "T" },
				-- A string like "nv", "nvo", "o", etc.
				labeled_modes = "v",
				multiline = true,
				-- Like `leap`s similar argument (call-specific overrides).
				-- E.g.: opts = { equivalence_classes = {} }
				opts = {},
			})
		end,
	},

	{
		"nvim-telescope/telescope.nvim",
		-- cmd = 'Telescope',
		config = function()
			require("plugins.telescope")
		end,
	},
	"nvim-telescope/telescope-live-grep-args.nvim",
	"nvim-telescope/telescope-ui-select.nvim",
	--"nvim-lua/plenary.nvim",

	-- tree syntc
	{
		"nvim-treesitter/nvim-treesitter",
		config = function()
			require("plugins.treesitter")
		end,
	},
	"nvim-treesitter/nvim-treesitter-context",

	-- cmp
	"hrsh7th/cmp-nvim-lsp",
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-path",
	"hrsh7th/cmp-cmdline",
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		config = function()
			require("plugins.cmp")
		end,
	},
	"onsails/lspkind.nvim",

	-- 代码段提示
	{

		"L3MON4D3/LuaSnip",
		event = "InsertEnter",
		run = "make install_jsregexp",
		dependencies = {
			"saadparwaiz1/cmp_luasnip", -- Snippets source for nvim-cmp
			"rafamadriz/friendly-snippets", --代码段合集
		},
		config = function()
			require("plugins.luasnip")
		end,
	},

	-- status line
	{
		"nvim-lualine/lualine.nvim",
		config = function()
			require("plugins.lualine")
		end,
	},

	-- file explorer
	{
		"nvim-tree/nvim-tree.lua",
		cmd = {
			"NvimTreeOpen",
			"NvimTreeClose",
			"NvimTreeToggle",
			"NvimTreeFindFile",
			"NvimTreeFindFileToggle",
		},
		config = function()
			require("plugins.nvim-tree")
		end,
	},

	-- git
	"tpope/vim-fugitive",
	{
		"wintermute-cell/gitignore.nvim",
		cmd = { "Gitignore" },
		config = function()
			require("gitignore")
		end,
	},
	{
		"kdheepak/lazygit.nvim",
		cmd = "LazyGit",
		requires = {
			"nvim-lua/plenary.nvim",
		},
	},
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup()
		end,
	},

	-- indent line
	{
		"lukas-reineke/indent-blankline.nvim",
		event = "BufRead",
		config = function()
			require("plugins.indent_blankline")
		end,
	},

	-- auto pairs
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			require("nvim-autopairs").setup()
		end,
	},
	{
		"kylechui/nvim-surround",
		version = "*", -- Use for stability; omit to use `main` branch for the latest features
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({
				-- Configuration here, or leave empty to use defaults
			})
		end,
	},

	-- quick comment

	{
		"numToStr/Comment.nvim",
		opts = {
			-- add any options here
		},
		lazy = false,
	},

	-- which key
	{
		"folke/which-key.nvim",
		config = function()
			require("plugins.which-key")
		end,
	},

	{
		"akinsho/toggleterm.nvim",
		config = function()
			require("plugins.toggleterm")
		end,
	},

	{

		"iamcco/markdown-preview.nvim",
		ft = "markdown",
		config = function()
			vim.fn["mkdp#util#install"]()
		end,
	},

	--debug for python
	{
		"mfussenegger/nvim-dap",
		-- cmd = { "Telescope" },
		config = function()
			require("plugins.dap")
		end,
	},
	"jay-babu/mason-nvim-dap.nvim",
	{
		"rcarriga/nvim-dap-ui",
	},
	"mfussenegger/nvim-dap-python",
	"nvim-telescope/telescope-dap.nvim",
	"theHamsta/nvim-dap-virtual-text",
	{
		"Weissle/persistent-breakpoints.nvim",
		cmd = "PersistentBreakpointsToggle",
		config = function()
			require("persistent-breakpoints").setup({
				load_breakpoints_event = { "BufReadPost" },
			})
		end,
	},

	-- folding
	{
		"kevinhwang91/nvim-ufo",
		dependencies = "kevinhwang91/promise-async",
		config = function()
			require("plugins.ufo")
		end,
	},

	-- theme for neovim
	{
		"rose-pine/neovim",
		name = "rose-pine",
		priority = 1000,
		-- 'NLKNguyen/papercolor-theme',
		--config = function()
		--vim.o.background = "light" -- or "dark" for light mode
		--vim.cmd("colorscheme PaperColor")
		--end
	},
	"NLKNguyen/papercolor-theme",
	"morhetz/gruvbox",
	"altercation/vim-colors-solarized",

	-- go to small window
	{
		"rmagatti/goto-preview",
		event = "LspAttach",
		config = function()
			require("plugins.goto-preview")
		end,
	},

	-- quickfix window
	{
		"kevinhwang91/nvim-bqf",
		ft = "qf",
		config = function()
			require("plugins.bqf")
		end,
	},

	-- optional
	--"junegunn/fzf",
	{
		"ibhagwan/fzf-lua",
		-- cmd = { 'FzfLua' },
		-- optional for icon support
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			-- calling `setup` is optional for customization
			require("plugins.fzf")
		end,
	},
	-- lazy.nvim

	-- habit
	{
		"m4xshen/hardtime.nvim",
		dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
		opts = {},
	},

	-- diff
	{
		"sindrets/diffview.nvim",
		config = function()
			-- init.lua 版本
			require("diffview").setup({
				enhanced_diff_hl = true,
				view = {
					merge_tool = {
						layout = "diff3_mixed",
					},
				},
			})
		end,
	},
	-- start screen
	{
		"goolord/alpha-nvim",
		config = function()
			--require'alpha'.setup(require'alpha.themes.dashboard'.config)
			require("alpha").setup(require("alpha.themes.startify").config)
		end,
	},

	-- file browser

	{
		"nvim-telescope/telescope-file-browser.nvim",
		-- cmd = 'Telescope',
		dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
	},

	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
	},
	--chatgpt
	-- {
	--     "jackMort/ChatGPT.nvim",
	--     event = "VeryLazy",
	--     dependencies = {
	--         "MunifTanjim/nui.nvim",
	--         "nvim-lua/plenary.nvim",
	--         "folke/trouble.nvim",
	--         "nvim-telescope/telescope.nvim"
	--     }
	-- },

	-- unit test
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		cmd = { "NeotestRun", "NeotestSummary" },
		config = function()
			require("plugins.neotest")
		end,
	},
	"nvim-neotest/neotest-python",
	{
		"andythigpen/nvim-coverage",
		requires = "nvim-lua/plenary.nvim",
		config = function()
			require("plugins.coverage")
		end,
		-- Optional: needed for PHP when using the cobertura parser
		rocks = { "lua-xmlreader" },
		--config = function()
		--require("coverage").setup()
		--end,
	},
	{
		"norcalli/nvim-colorizer.lua",
		config = function()
			require("colorizer").setup()
		end,
	},
	--project manager
	{
		"ahmedkhalf/project.nvim",
		-- cmd = "Telescope",
		config = function()
			require("project_nvim").setup({
				scope_chdir = "tab",
			})
		end,
	},
	-- gitlab
	-- {
	--     "harrisoncramer/gitlab.nvim",
	--     dependencies = {
	--         "MunifTanjim/nui.nvim",
	--         "nvim-lua/plenary.nvim",
	--         "sindrets/diffview.nvim",
	--         "stevearc/dressing.nvim",     -- Recommended but not required. Better UI for pickers.
	--         "nvim-tree/nvim-web-devicons" -- Recommended but not required. Icons in discussion tree.
	--     },
	--     enabled = true,
	--     build = function() require("gitlab.server").build(true) end, -- Builds the Go binary
	--     config = function()
	--         require("gitlab").setup({
	--             debug = {
	--                 go_request = true,
	--                 go_response = true,
	--             },
	--         })
	--     end,
	-- },

	{
		"nvimdev/lspsaga.nvim",
		event = "LspAttach",
		config = function()
			require("plugins.lspsaga")
		end,
		dependencies = {
			"nvim-treesitter/nvim-treesitter", -- optional
			"nvim-tree/nvim-web-devicons", -- optional
		},
	},
	{
		"michaelb/sniprun",
		branch = "master",

		build = "sh install.sh",
		cmd = "SnipRun",
		-- do 'sh install.sh 1' if you want to force compile locally
		-- (instead of fetching a binary from the github release). Requires Rust >= 1.65

		config = function()
			require("sniprun").setup({
				-- your options
			})
		end,
	},
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		opts = {},
		config = function()
			require("plugins.conform")
		end,
	},
	-- {
	--     'pwntester/octo.nvim',
	--     requires = {
	--         'nvim-lua/plenary.nvim',
	--         'nvim-telescope/telescope.nvim',
	--         -- OR 'ibhagwan/fzf-lua',
	--         'nvim-tree/nvim-web-devicons',
	--     },
	--     --config = function()
	--     --require "octo".setup()
	--     --end
	-- },
	-- image show
	{
		-- "edluffy/hologram.nvim",
		--config = function()
		--require('hologram').setup {
		--auto_display = true -- WIP automatic markdown image display, may be prone to breaking
		--}
		--end
	},
	{
		"mikesmithgh/kitty-scrollback.nvim",
		enabled = true,
		lazy = true,
		cmd = { "KittyScrollbackGenerateKittens", "KittyScrollbackCheckHealth" },
		event = { "User KittyScrollbackLaunch" },
		-- version = '*', -- latest stable version, may have breaking changes if major version changed
		-- version = '^4.0.0', -- pin major version, include fixes and features that do not have breaking changes
		config = function()
			require("kitty-scrollback").setup()
		end,
	},
	{
		"willothy/flatten.nvim",
		config = function()
			require("flatten").setup({
				window = {
					open = "vsplit",
				},
			})
		end,
		-- or pass configuration with
		-- opts = {  }
		-- Ensure that it runs first to minimize delay when opening file from terminal
		lazy = false,
		priority = 1001,
	},
	-- zen
	{
		"folke/zen-mode.nvim",
	},
	{
		"AckslD/nvim-neoclip.lua",
		dependencies = {
			-- you'll need at least one of these
			-- {'nvim-telescope/telescope.nvim'},
			-- {'ibhagwan/fzf-lua'},
		},
		config = function()
			require("neoclip").setup()
		end,
	},
	{
		"nvimtools/none-ls.nvim",
		config = function()
			require("plugins.none_ls")
		end,
	},
	-- ui
	{
		"stevearc/dressing.nvim",
		opts = {},
	},
	{
		keys = {
			{
				"<leader>ar",
				"<cmd>CellularAutomaton make_it_rain<cr>",
				desc = "Rain",
			},
			{
				"<leader>ag",
				"<cmd>CellularAutomaton game_of_life<cr>",
				desc = "Game",
			},
			{
				"<leader>as",
				"<cmd>CellularAutomaton scramble<cr>",
				desc = "Game",
			},
		},
		"eandrju/cellular-automaton.nvim",
	},
	-- task
	{
		"stevearc/overseer.nvim",
		opts = {},
	},
	"uga-rosa/translate.nvim",
}
