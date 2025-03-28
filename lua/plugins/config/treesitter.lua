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
		-- disable = { "css", "text" }, -- list of language that will be disabled
		disable = function(lang, buf)
			local max_filesize = 100 * 1024 -- 100 KB
			local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
			if ok and stats and stats.size > max_filesize then
				return true
			end
		end,
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
