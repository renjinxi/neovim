return {
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		config = function()
			require("plugins.config.mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = false,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"prettierd",
					"eslint_d",
					"goimports",
					"google-java-format",
					"ktlint",
					"java-debug-adapter",
					"java-test",
				},
				auto_update = false,
				run_on_start = true,
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			require("plugins.config.lsp")
		end,
	},
	{ "b0o/schemastore.nvim", lazy = true },
	{
		"antosha417/nvim-lsp-file-operations",
		event = "LspAttach",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-tree.lua",
		},
	},
	{
		"rmagatti/goto-preview",
		event = "LspAttach",
		config = function()
			local post_open_hook = function(_, win)
				vim.api.nvim_set_option_value("winhighlight", "Normal:", { win = win })
			end
			require("goto-preview").setup({
				post_open_hook = post_open_hook,
			})
		end,
	},
	{
		"mfussenegger/nvim-jdtls",
		ft = { "java", "kotlin" },
		dependencies = {
			"mfussenegger/nvim-dap",
		},
	},
	"hrsh7th/cmp-nvim-lsp",
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-path",
	"hrsh7th/cmp-cmdline",
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		config = function()
			require("plugins.config.cmp")
		end,
	},
	"onsails/lspkind.nvim",
	{
		"L3MON4D3/LuaSnip",
		event = "InsertEnter",
		run = "make install_jsregexp",
		dependencies = {
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},
		config = function()
			require("plugins.config.luasnip")
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		config = function()
			require("plugins.config.treesitter")
		end,
	},
	"nvim-treesitter/nvim-treesitter-context",
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			require("nvim-autopairs").setup()
		end,
	},
	{
		"windwp/nvim-ts-autotag",
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	},
	{
		"kylechui/nvim-surround",
		version = "*",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({})
		end,
	},
	{
		"andymass/vim-matchup",
		config = function()
			vim.g.matchup_matchparen_enabled = 0
			vim.g.matchup_matchparen_offscreen = { method = "popup" }
		end,
	},
	{
		"numToStr/Comment.nvim",
		opts = {},
		lazy = false,
	},
	{
		"kevinhwang91/nvim-ufo",
		dependencies = "kevinhwang91/promise-async",
		config = function()
			require("plugins.config.ufo")
		end,
	},
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		config = function()
			require("plugins.config.conform")
		end,
	},
	{
		"folke/trouble.nvim",
		config = function()
			local config = require("plugins.config.trouble")
			require("trouble").setup(config.opts)
		end,
		cmd = function()
			return require("plugins.config.trouble").cmd
		end,
		keys = function()
			return require("plugins.config.trouble").keys
		end,
	},
}
