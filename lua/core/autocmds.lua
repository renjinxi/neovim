local M = {}

local function create_group(name)
	return vim.api.nvim_create_augroup(name, { clear = true })
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

	-- CSV文件自动启用CsvView - 使用专门的CSV配置模块
	local csv_config_ok, csv_config = pcall(require, "core.csv-config")
	if csv_config_ok then
		csv_config.setup()
	end

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
		-- command = "if mode() != 'c' | checktime | endif",
		callback = function()
			if vim.bo.buftype == "" and vim.api.nvim_get_mode().mode ~= "c" then
				vim.cmd("checktime")
			end
		end,
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

	-- 动态将当前 servername 写入文件，供 Skim 反向搜索使用
	local function set_server_name()
		local nvim_server_file = "/tmp/curnvimserver.txt"
		if vim.v.servername and vim.v.servername ~= "" then
			local cmd = string.format("echo '%s' > %s", vim.v.servername, nvim_server_file)
			vim.fn.system(cmd)
		end
	end

	-- 多个时机更新 servername 文件，确保同步
	vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "BufRead" }, {
		group = augroup,
		pattern = "tex",
		callback = set_server_name,
	})

	-- 启动时也更新一次
	vim.api.nvim_create_autocmd("VimEnter", {
		group = augroup,
		callback = set_server_name,
	})
	
	-- 输入法自动切换
	local im_switch_ok, im_switch = pcall(require, "core.im-switch")
	if im_switch_ok then
		im_switch.setup()
	end
end

return M
