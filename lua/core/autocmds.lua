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

	-- 自动重载文件 - 现在由 vim-autoread 插件处理

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

	-- 终端模式快捷键
	require("plugins.config.terminal")

	-- Scratch buffer 命令 - 保存到 ~/notes/scratch/
	vim.api.nvim_create_user_command("Scratch", function()
		local scratch_dir = vim.fn.expand("~/notes/scratch")
		vim.fn.mkdir(scratch_dir, "p")
		local filename = os.date("%Y-%m-%d_%H%M%S") .. ".md"
		local filepath = scratch_dir .. "/" .. filename
		vim.cmd("vnew " .. filepath)
		vim.bo.filetype = "markdown"
	end, {})

	-- Send 命令：发送内容到指定窗口的终端
	-- 用法: :Send [win_nr] - 发送并跳转
	--       :Send! [win_nr] - 发送但不跳转（后台发送）
	vim.api.nvim_create_user_command("Send", function(opts)
		local text
		if opts.range > 0 then
			local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
			text = table.concat(lines, "\n")
		else
			text = vim.fn.getreg("+")
		end

		local win_nr = tonumber(opts.args) or 1
		local win_id = vim.fn.win_getid(win_nr)
		if win_id == 0 then
			return
		end

		local buf = vim.api.nvim_win_get_buf(win_id)
		local chan = vim.bo[buf].channel

		if chan then
			vim.fn.chansend(chan, text)
			vim.defer_fn(function()
				vim.fn.chansend(chan, "\x0d")
			end, 50)
		end

		-- bang (!) 表示后台发送，不跳转
		if not opts.bang then
			vim.fn.win_gotoid(win_id)
			if vim.bo.buftype == "terminal" then
				vim.cmd("startinsert!")
			end
		end
	end, { nargs = "?", range = true, bang = true })

	-- SendBuf 命令：发送内容到指定窗口的普通 buffer
	-- 用法: :SendBuf [win_nr] - 发送并跳转
	--       :SendBuf! [win_nr] - 发送但不跳转（后台发送）
	-- 默认追加到末尾，可用 @行号 指定插入位置，如 :SendBuf 2@10
	vim.api.nvim_create_user_command("SendBuf", function(opts)
		local text
		if opts.range > 0 then
			local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
			text = lines
		else
			text = vim.split(vim.fn.getreg("+"), "\n", { plain = true })
		end

		-- 解析参数：win_nr@line_nr 或 win_nr
		local args = opts.args or ""
		local win_nr, target_line = args:match("^(%d*)@?(%d*)$")
		win_nr = tonumber(win_nr) or 1
		target_line = tonumber(target_line)

		local win_id = vim.fn.win_getid(win_nr)
		if win_id == 0 then
			print("Invalid window number: " .. win_nr)
			return
		end

		local buf = vim.api.nvim_win_get_buf(win_id)

		-- 确定插入位置
		local insert_at
		if target_line then
			insert_at = target_line - 1
		else
			insert_at = vim.api.nvim_buf_line_count(buf)
		end

		-- 插入内容
		vim.api.nvim_buf_set_lines(buf, insert_at, insert_at, false, text)

		-- 滚动目标窗口到插入位置
		local new_cursor_line = insert_at + #text
		vim.api.nvim_win_set_cursor(win_id, { new_cursor_line, 0 })

		-- bang (!) 表示后台发送，不跳转
		if not opts.bang then
			vim.fn.win_gotoid(win_id)
		end
	end, { nargs = "?", range = true, bang = true })

	-- Windows 命令：临时显示所有窗口号
	-- 浮动窗口用 [N] 标记，普通窗口用 N 标记
	vim.api.nvim_create_user_command("Windows", function()
		local wins = vim.api.nvim_tabpage_list_wins(0)
		local popups = {}
		for _, win in ipairs(wins) do
			local config = vim.api.nvim_win_get_config(win)
			local nr = vim.api.nvim_win_get_number(win)
			local label = tostring(nr)
			local buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, { " " .. label .. " " })
			local width = vim.api.nvim_win_get_width(win)
			local height = vim.api.nvim_win_get_height(win)
			local popup = vim.api.nvim_open_win(buf, false, {
				relative = "win",
				win = win,
				row = height / 2 - 1,
				col = width / 2 - 2,
				width = #label + 2,
				height = 1,
				style = "minimal",
				border = "rounded",
			})
			table.insert(popups, popup)
		end
		vim.defer_fn(function()
			for _, p in ipairs(popups) do
				pcall(vim.api.nvim_win_close, p, true)
			end
		end, 1500)
	end, {})

	-- Claude 命令：启动半屏 Claude
	vim.api.nvim_create_user_command("Claude", function()
		local fn = require("plugins.keymaps.functions")
		fn.claude_half_screen_toggle()
	end, {})

	-- R 命令：在 float 窗口显示 shell 命令输出
	vim.api.nvim_create_user_command("R", function(opts)
		local output = vim.fn.system(opts.args)
		local lines = vim.split(output, "\n")

		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

		local width = math.min(80, vim.o.columns - 4)
		local height = math.min(#lines, vim.o.lines - 4)

		vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			row = vim.o.lines - height - 4,
			col = 1,
			width = width,
			height = height,
			style = "minimal",
			border = "rounded",
		})

		vim.bo[buf].buftype = "nofile"
		vim.keymap.set("n", "q", ":close<CR>", { buffer = buf, silent = true })
		vim.keymap.set("n", "<Esc>", ":close<CR>", { buffer = buf, silent = true })
	end, { nargs = "+", complete = "shellcmd" })

	-- Claude 命令：在新 tab 启动 Claude
	-- :Claude      - 默认 API 1
	-- :Claude1     - API 1
	-- :Claude2     - API 2
	vim.api.nvim_create_user_command("Claude", function()
		local fn = require("plugins.keymaps.functions")
		fn.tab_terminal_claude(1)
	end, {})

	vim.api.nvim_create_user_command("Claude1", function()
		local fn = require("plugins.keymaps.functions")
		fn.tab_terminal_claude(1)
	end, {})

	vim.api.nvim_create_user_command("Claude2", function()
		local fn = require("plugins.keymaps.functions")
		fn.tab_terminal_claude(2)
	end, {})

	-- ClaudeNew 命令：新建 Claude 实例
	-- :ClaudeNew   - 默认 API 1
	-- :ClaudeNew1  - API 1
	-- :ClaudeNew2  - API 2
	vim.api.nvim_create_user_command("ClaudeNew", function()
		local fn = require("plugins.keymaps.functions")
		fn.tab_terminal_claude_new(1)
	end, {})

	vim.api.nvim_create_user_command("ClaudeNew1", function()
		local fn = require("plugins.keymaps.functions")
		fn.tab_terminal_claude_new(1)
	end, {})

	vim.api.nvim_create_user_command("ClaudeNew2", function()
		local fn = require("plugins.keymaps.functions")
		fn.tab_terminal_claude_new(2)
	end, {})

	-- Codex 命令：在新 tab 启动 Codex
	vim.api.nvim_create_user_command("Codex", function()
		local fn = require("plugins.keymaps.functions")
		fn.tab_terminal_codex()
	end, {})

	-- 终端 buffer 关闭时终止进程
	vim.api.nvim_create_autocmd("BufUnload", {
		group = create_group("CleanupTerminals"),
		callback = function(args)
			local buf = args.buf
			if vim.bo[buf].buftype == "terminal" then
				local chan = vim.bo[buf].channel
				if chan and chan > 0 then
					pcall(vim.fn.jobstop, chan)
				end
			end
		end,
	})

	-- 退出 nvim 时关闭所有终端进程
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = create_group("CleanupTerminalsOnExit"),
		callback = function()
			local ok, fn = pcall(require, "plugins.keymaps.functions")
			if ok and fn.shutdown_all_terminals then
				fn.shutdown_all_terminals()
			end
		end,
	})
end

return M
