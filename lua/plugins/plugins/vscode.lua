return {
	-- 快速移动
	{
		"ggandor/leap.nvim",
		config = function()
			require("leap").add_default_mappings()
		end,
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
