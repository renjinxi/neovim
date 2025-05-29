local M = {}

M.settings = {
	Lua = {
		diagnostics = {
			globals = { "vim", "bit", "use", "describe", "it", "before_each", "after_each" },
		},
		workspace = {
			-- 更高效的 library 设置
			library = {
				vim.fn.expand("$VIMRUNTIME/lua"),
				vim.fn.expand("$VIMRUNTIME/lua/vim/lsp"),
				vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua/lazy",
			},
			checkThirdParty = false,
			maxPreload = 100000,
			preloadFileSize = 10000,
		},
		telemetry = {
			enable = false,
		},
		completion = {
			callSnippet = "Replace",
		},
		-- 减少不必要的诊断
		hint = {
			enable = true,
		},
	},
}

return M
