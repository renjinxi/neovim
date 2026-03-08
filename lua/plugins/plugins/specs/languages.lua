return {
	{
		"linux-cultist/venv-selector.nvim",
		dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim", "mfussenegger/nvim-dap-python" },
		config = function()
			require("venv-selector").setup({
				name = ".venv",
			})
		end,
	},
	{
		"lervag/vimtex",
		ft = { "tex" },
		config = function()
			require("plugins.config.vimtex")
		end,
	},
	{
		"kdheepak/cmp-latex-symbols",
		ft = { "tex" },
	},
	{
		"iamcco/markdown-preview.nvim",
		ft = "markdown",
		config = function()
			vim.fn["mkdp#util#install"]()
		end,
	},
	{
		"hat0uma/csvview.nvim",
		opts = function()
			return require("plugins.config.csvview")
		end,
		cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
	},
	{
		"rest-nvim/rest.nvim",
		dependencies = {
			"j-hui/fidget.nvim",
		},
		rocks = { "xml2lua", "mimetypes" },
		ft = { "http" },
		config = function()
			require("rest-nvim").setup()
		end,
	},
	{
		"tpope/vim-dadbod",
		cmd = { "DB", "DBUI" },
	},
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = {
			"tpope/vim-dadbod",
			"kristijanhusak/vim-dadbod-completion",
		},
		cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
		init = function()
			vim.g.db_ui_use_nerd_fonts = 1
			vim.g.db_ui_show_database_icon = 1
			vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
		end,
	},
	{
		"kristijanhusak/vim-dadbod-completion",
		ft = { "sql", "mysql", "plsql" },
		lazy = true,
	},
	{
		"kawre/leetcode.nvim",
		build = ":TSUpdate html",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-treesitter/nvim-treesitter",
			"nvim-telescope/telescope.nvim",
		},
		opts = {
			lang = "python3",
			storage = {
				home = vim.fn.stdpath("data") .. "/leetcode",
				cache = vim.fn.stdpath("cache") .. "/leetcode",
			},
		},
		config = function(_, opts)
			require("leetcode").setup(opts)
		end,
	},
}
