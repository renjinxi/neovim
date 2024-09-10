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

local lsp = vim.lsp
local function stop_all_lsp()
	lsp.stop_client(lsp.get_active_clients())
end

local function start_lsp()
	vim.cmd("LspStart")
end

api.nvim_create_autocmd("TabEnter", {
	group = create_group("lsp_group"), -- 使用前面创建的自动命令组
	callback = function()
		-- 在切换到新的 tab 时先停止所有的 LSP
		stop_all_lsp()

		-- 等待一段时间后重新启动 LSP
		vim.defer_fn(start_lsp, 1000)
	end,
})

vim.api.nvim_create_autocmd("VimEnter", {
	group = create_group("lazy_auto_update"),
	callback = function()
		if require("lazy.status").has_updates then
			require("lazy").update({ show = false })
		end
	end,
})
vim.api.nvim_create_autocmd("VimEnter", {
	group = create_group("ts_auto_update"),
	callback = function()
		vim.cmd("TSUpdate")
	end,
})

-- 自动更新 Mason 插件和工具
-- vim.api.nvim_create_autocmd("VimEnter", {
-- 	group = create_group("mason_auto_update"),
-- 	callback = function()
-- 		vim.cmd("MasonUpdate")
-- 	end,
-- })
