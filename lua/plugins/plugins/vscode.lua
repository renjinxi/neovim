return {
	-- 快速移动 (现代化的移动插件)
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = function()
			return require("plugins.config.flash")
		end,
		keys = {
			{
				"s",
				mode = { "n", "x", "o" },
				function()
					require("flash").jump()
				end,
				desc = "Flash 跳转",
			},
			{
				"S",
				mode = { "n", "x", "o" },
				function()
					require("flash").treesitter()
				end,
				desc = "Flash Treesitter 选择",
			},
		},
	},
	-- 快速环绕
	{
		"kylechui/nvim-surround",
		version = "*",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({})
		end,
	},
	-- 注释
	{
		"numToStr/Comment.nvim",
		opts = {},
		lazy = false,
	},
	-- 文本对象
	{
		"andymass/vim-matchup",
		config = function()
			vim.g.matchup_matchparen_enabled = 0
			vim.g.matchup_matchparen_offscreen = { method = "popup" }
		end,
	},
}
