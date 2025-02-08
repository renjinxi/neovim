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
}

if vim.g.vscode then
	return lazy.setup("config.vscode_plugins", opt)
else
	return lazy.setup("config.plugins", opt)
end
