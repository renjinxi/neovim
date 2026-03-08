return {
	{
		"mikesmithgh/kitty-scrollback.nvim",
		enabled = true,
		lazy = true,
		cmd = { "KittyScrollbackGenerateKittens", "KittyScrollbackCheckHealth" },
		event = { "User KittyScrollbackLaunch" },
		config = function()
			require("kitty-scrollback").setup({
				on_attach = function()
					vim.g.kitty_scrollback_enabled = true
				end,
			})
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
		lazy = false,
		priority = 1001,
	},
	{
		"djoshea/vim-autoread",
		config = function()
			vim.g.autoread_debounce_time = 100
		end,
	},
	{
		"Pocco81/auto-save.nvim",
		config = function()
			require("plugins.config.autosave")
		end,
	},
	{
		"kevinhwang91/nvim-bqf",
		ft = "qf",
		config = function()
			require("plugins.config.bqf")
		end,
	},
	{
		"stevearc/overseer.nvim",
		config = function()
			require("plugins.config.overseer")
		end,
	},
	{
		"gbprod/yanky.nvim",
		dependencies = { "kkharji/sqlite.lua" },
		config = function()
			require("yanky").setup({
				ring = {
					history_length = 100,
					storage = "sqlite",
					sync_with_numbered_registers = true,
				},
				system_clipboard = {
					sync_with_ring = true,
				},
				highlight = {
					on_put = true,
					on_yank = true,
					timer = 200,
				},
			})
			pcall(function()
				require("telescope").load_extension("yank_history")
			end)
		end,
	},
	"mbbill/undotree",
	{
		"matbme/JABS.nvim",
		config = function()
			require("jabs").setup({})
		end,
	},
	{
		"amitds1997/remote-nvim.nvim",
		branch = "fix/neovim-install-script",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-telescope/telescope.nvim",
		},
		config = function()
			require("plugins.config.remote-nvim")
		end,
	},
}
