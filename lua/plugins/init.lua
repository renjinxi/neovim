local M = {}

function M.setup()
	vim.o.background = "light" -- or "dark" for light mode
	local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
	if not vim.loop.fs_stat(lazypath) then
		vim.fn.system({
			"git",
			"clone",
			"--filter=blob:none",
			"https://github.com/folke/lazy.nvim.git",
			"--branch=stable", -- latest stable release
			lazypath,
		})
	end
	vim.opt.rtp:prepend(lazypath)

	local status_ok, lazy = pcall(require, "lazy")

	if not status_ok then
		return
	end

	local opt = {
		install = {
			missing = true,
			--colorscheme = { "PaperColor" },
		},
		checker = {
			enabled = false, -- 禁用自动检查更新
		},
	}
	lazy.setup("plugins.plugins", opt)
	if not vim.g.vscode then
		-- 主题已在lazy插件配置中设置，这里只需要加载自定义高亮（如果有的话）
		require("plugins.theme").setup()
	end
	require("plugins.keymaps").setup()
end

return M
