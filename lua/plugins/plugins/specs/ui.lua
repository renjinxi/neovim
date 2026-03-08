return {
	{
		"rebelot/heirline.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("plugins.config.heirline")
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		version = "v3.8.2",
		event = "BufRead",
		config = function()
			require("ibl").setup({
				indent = { char = "¦" },
			})
		end,
	},
	{
		"nvim-tree/nvim-web-devicons",
		config = function()
			require("nvim-web-devicons").setup({
				override = {
					default_icon = {
						icon = "",
						color = "#6d8086",
						name = "Default",
					},
				},
				strict = true,
			})
		end,
	},
	{
		"nvimdev/dashboard-nvim",
		event = "VimEnter",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("plugins.config.dashboard")
		end,
	},
	{ "stevearc/dressing.nvim", opts = {} },
	{
		"brenoprata10/nvim-highlight-colors",
		config = function()
			require("nvim-highlight-colors").setup({
				render = "background",
				enable_named_colors = true,
				enable_tailwind = true,
			})
		end,
	},
	{
		"rose-pine/neovim",
		name = "rose-pine",
		priority = 1000,
		config = function()
			require("plugins.config.rose-pine")
		end,
	},
	"NLKNguyen/papercolor-theme",
	"morhetz/gruvbox",
	"altercation/vim-colors-solarized",
	{
		"folke/which-key.nvim",
		config = function()
			require("which-key").setup({
				delay = function()
					return 600
				end,
			})
		end,
	},
	{
		"folke/zen-mode.nvim",
		config = function()
			require("zen-mode").setup(require("plugins.config.zen-mode"))
		end,
	},
	{
		"m4xshen/hardtime.nvim",
		dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
		opts = {},
	},
	{
		"eandrju/cellular-automaton.nvim",
		cmd = "CellularAutomaton",
	},
}
