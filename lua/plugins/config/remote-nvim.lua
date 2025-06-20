-- ================================
-- Remote Neovim配置
-- ================================

require("remote-nvim").setup({
	remote = {
		copy_dirs = {
			config = {
				base = vim.fn.stdpath("config"),
				dirs = "*",
				compression = { enabled = false },
			},
			data = {
				base = vim.fn.stdpath("data"),
				dirs = { "lazy" },
				compression = { enabled = true },
			},
		},
	},
	offline_mode = {
		enabled = false,
		no_github = false,
	},
}) 