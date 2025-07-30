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
		change_detection = {
			enabled = false, -- 禁用自动检测配置变化
		},
	}
	lazy.setup("plugins.plugins", opt)
	require("plugins.keymaps").setup()
end

return M
