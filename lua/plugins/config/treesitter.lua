require("nvim-treesitter.configs").setup({
	-- 安装所有可用的 parser，并确保 Java 和 Kotlin 被优先安装
	ensure_installed = "all",
	sync_install = false,

	-- Automatically install missing parsers when entering buffer
	auto_install = true,

	ignore_install = { "" }, -- List of parsers to ignore installing
	highlight = {
		enable = true, -- 启用 Treesitter 高亮
		-- disable = { "css", "text" }, -- list of language that will be disabled
		disable = function(lang, buf)
			local max_filesize = 100 * 1024 -- 100 KB
			local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
			if ok and stats and stats.size > max_filesize then
				return true
			end
		end,
		additional_vim_regex_highlighting = false,
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
