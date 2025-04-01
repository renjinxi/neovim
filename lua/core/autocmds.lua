local M = {}

local function create_group(name)
	return vim.api.nvim_create_augroup(name, { clear = true })
end

-- 创建一个异步函数来执行命令
local function async_run(cmd)
	local job = vim.fn.jobstart(cmd, {
		on_stdout = function(_, data)
			if data then
				vim.notify(table.concat(data, "\n"), vim.log.levels.INFO, {
					title = "Auto Update",
				})
			end
		end,
		on_stderr = function(_, data)
			if data then
				vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR, {
					title = "Auto Update Error",
				})
			end
		end,
	})
	return job
end

function M.setup()
	-- 搜索高亮
	if vim.g.vscode then
		return
	end
	vim.api.nvim_create_autocmd("BufEnter", {
		group = create_group("NoHlSearch"),
		callback = function()
			vim.opt.hlsearch = false
		end,
	})

	-- 相对行号
	local relative_group = create_group("RelativeNumber")
	vim.api.nvim_create_autocmd({ "WinEnter", "BufRead", "BufEnter", "FocusGained" }, {
		group = relative_group,
		pattern = "*",
		callback = function()
			if vim.wo.number then
				vim.wo.relativenumber = true
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave", "FocusLost" }, {
		group = relative_group,
		pattern = "*",
		callback = function()
			if vim.wo.number then
				vim.wo.relativenumber = false
			end
		end,
	})

	-- 缩进设置
	local indent_group = create_group("Indentation")
	vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
		group = indent_group,
		pattern = "*",
		callback = function()
			local default_value = 4
			local indent_table = {
				python = 4,
				markdown = 4,
				typescriptreact = 2,
				typescript = 2,
				javascript = 2,
				css = 2,
				lua = 4,
			}

			if vim.bo.filetype == "make" then
				vim.bo.expandtab = false
			else
				vim.bo.expandtab = true
			end

			vim.bo.autoindent = true
			local value = indent_table[vim.bo.filetype] or default_value
			vim.bo.tabstop = value
			vim.bo.softtabstop = value
			vim.bo.shiftwidth = value
		end,
	})

	-- 自动重载文件
	vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
		group = create_group("AutoReload"),
		pattern = "*",
		command = "if mode() != 'c' | checktime | endif",
	})

	-- 用户自定义自动命令
	local ok, custom_autocmds = pcall(require, "config.autocmds")
	if ok and type(custom_autocmds) == "function" then
		custom_autocmds()
	end

	local augroup = vim.api.nvim_create_augroup("CustomSettings", { clear = true })

	-- 确保折叠高亮设置在最后生效
	vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter", "BufEnter" }, {
		group = augroup,
		callback = function()
			vim.cmd([[
                hi Folded guifg=NONE guibg=NONE gui=NONE cterm=NONE
                hi FoldColumn guifg=NONE guibg=NONE gui=NONE cterm=NONE
            ]])
		end,
	})

	-- 创建启动时自动更新的命令组
	local auto_update_group = vim.api.nvim_create_augroup("AutoUpdate", { clear = true })

	-- 在 VimEnter 事件时执行更新
	vim.api.nvim_create_autocmd("VimEnter", {
		group = auto_update_group,
		callback = function()
			-- 使用 vim.schedule 确保在 Neovim 完全启动后执行
			vim.schedule(function()
				-- 在后台执行更新命令
				async_run({ "nvim", "--headless", "-c", "Lazy update", "-c", "qa" })
				async_run({ "nvim", "--headless", "-c", "TSUpdate", "-c", "qa" })
				async_run({ "nvim", "--headless", "-c", "Mason", "-c", "MasonUpdate", "-c", "qa" })
			end)
		end,
	})
end

return M
