local api = vim.api
local opt = vim.opt

local function create_group(name)
	return vim.api.nvim_create_augroup(name, { clear = true })
end

vim.api.nvim_create_autocmd("BufEnter", {
	group = create_group("NoHlSearch"),
	callback = function()
		vim.opt.hlsearch = false
	end,
})

local function set_indent()
	local default_value = 4
	local indent_table = {
		python = 4,
		markdown = 4,
		typescriptreact = 2,
		css = 2,
		typescript = 2,
		javascript = 2,
		--toml = 2,
		--c = 4,
	}

	if vim.bo.filetype == "make" then
		opt.expandtab = false
	else
		opt.expandtab = true
	end
	opt.autoindent = true
	for key, value in pairs(indent_table) do
		if vim.bo.filetype == key then
			opt.tabstop = value
			opt.softtabstop = value
			opt.shiftwidth = value
			return
		end
	end
	opt.tabstop = default_value
	opt.softtabstop = default_value
	opt.shiftwidth = default_value
end

api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	pattern = "*",
	group = create_group("indent_group"),
	desc = "set indent for file",
	callback = set_indent,
})

-- reload buffer file when file changed on disk
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
	command = "if mode() != 'c' | checktime | endif",
	pattern = { "*" },
})

local function set_relativenumber()
	vim.opt.relativenumber = true
end

local function set_norelativenumber()
	vim.opt.relativenumber = false
end
api.nvim_create_autocmd({ "WinEnter", "BufRead", "BufEnter", "FocusGained" }, {
	pattern = "*",
	group = create_group("relative_group"),
	desc = "set relativenumber for file",
	callback = set_relativenumber,
})

api.nvim_create_autocmd({ "WinLeave", "BufLeave", "FocusLost" }, {
	pattern = "*",
	group = create_group("no_relative_group"),
	desc = "set norelativenumber for file",
	callback = set_norelativenumber,
})

vim.api.nvim_create_autocmd("VimEnter", {
	group = create_group("lazy_auto_update"),
	callback = function()
		if vim.g.kitty_scrollback_enabled then
			return
		end
		if require("lazy.status").has_updates then
			require("lazy").update({ show = false })
		end
	end,
})
vim.api.nvim_create_autocmd("VimEnter", {
	group = create_group("ts_auto_update"),
	callback = function()
		if vim.g.kitty_scrollback_enabled then
			return
		end
		vim.cmd("TSUpdate")
	end,
})

-- 自动更新 Mason 插件和工具
-- vim.api.nvim_create_autocmd("VimEnter", {
-- 	group = create_group("mason_auto_update"),
-- 	callback = function()
-- 		vim.cmd("MasonUpdate")
-- 	end,
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "json" },
	callback = function()
		vim.api.nvim_set_option_value("formatprg", "jq", { scope = "local" })
	end,
})
