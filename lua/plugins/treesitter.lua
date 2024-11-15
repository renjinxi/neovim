require("nvim-treesitter.configs").setup({
	ensure_installed = "all", -- one of "all" or a list of languages
	sync_install = false,

	-- Automatically install missing parsers when entering buffer
	--   -- Recommendation: set to false if you don't have `tree-sitter` CLI
	--   installed locally
	auto_install = true,
	ignore_install = { "" }, -- List of parsers to ignore installing
	highlight = {
		enable = true, -- false will disable the whole extension
		disable = { "css", "text" }, -- list of language that will be disabled
	},
	autopairs = {
		enable = true,
	},

	--indent = { enable = true, disable = { "python", "css" } },
	indent = { enable = true },
	matchup = {
		enable = true, -- Enable vim-matchup integration
	},
})
