local M = {}
local status_ok, which_key = pcall(require, "which-key")
if not status_ok then
	return
end

-- 添加reload_config模块
local reload_status_ok, reload = pcall(require, "core.reload")
if not reload_status_ok then
	vim.notify("无法加载 reload 模块", vim.log.levels.ERROR)
	return
end

local function get_project_root()
	-- 获取当前项目的根路径，假设使用 Git
	local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null")
	if git_root ~= "" then
		return git_root:gsub("%s+", "") -- 去除多余的空格和换行
	end
	return nil -- 如果找不到项目根路径，返回 nil
end

local function create_new_file()
	-- 获取当前缓冲区的路径
	local current_directory = vim.fn.expand("%:p:h")
	local directory = current_directory

	if directory == "" then
		-- 如果没有路径，则使用项目根路径
		directory = get_project_root()
		if not directory then
			print("Error: No project root found.")
			return
		end
	end

	-- 在输入提示中显示当前目录
	vim.ui.input({
		prompt = "New File Name (in " .. directory .. "): ",
		default = directory .. "/", -- 默认以当前目录开头
	}, function(new_name)
		if not new_name or new_name == "" then
			print("File creation cancelled.")
			return
		end

		-- 构建新的文件路径
		local new_path = new_name
		local dir = new_path:match("(.*/)")
		if not vim.loop.fs_stat(dir) then
			os.execute("mkdir -p " .. dir)
		end

		-- 尝试创建新文件
		local file = io.open(new_path, "w") -- 以写入模式打开文件
		if not file then
			print("Error creating file: " .. new_path)
			return
		end
		file:close() -- 关闭文件

		-- 打开新创建的文件
		vim.cmd("e " .. new_path)
		print("File created: " .. new_name)
	end)
end

local function rename_current_file()
	-- 获取当前文件的完整路径
	local old_path = vim.fn.expand("%:p")
	local current_buffer_name = vim.fn.expand("%:t")
	local current_directory = vim.fn.expand("%:p:h")

	-- 在输入提示中显示当前目录和文件名，允许用户修改
	local default_input = current_directory .. "/" .. current_buffer_name

	vim.ui.input({
		prompt = "New Path and Name: ",
		default = default_input,
	}, function(new_path)
		if not new_path or new_path == "" then
			print("Rename cancelled.")
			return
		end

		local dir = new_path:match("(.*/)")
		if not vim.loop.fs_stat(dir) then
			os.execute("mkdir -p " .. dir)
		end
		-- 尝试重命名文件
		local success, err = os.rename(old_path, new_path)
		if not success then
			print("Error renaming file: " .. err)
			return
		end

		-- 更新当前缓冲区的文件路径
		vim.cmd("e " .. new_path)
		print("File renamed to " .. new_path)
	end)
end
local open_project_in_new_tab = function()
	local input = vim.fn.input("Tab Name: ")
	if input ~= "" then
		vim.cmd("tabnew")
		vim.cmd("Telescope projects")
		vim.cmd("LualineRenameTab " .. input)
	end
end
local function toggle_neovide()
	vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen
end

local function toggle_hlsearch()
	vim.o.hlsearch = not vim.o.hlsearch
end

-- 通用复制函数
local function copy_to_clipboard(content, notify_message)
	if not content or content == "" then
		vim.notify("没有内容可复制", vim.log.levels.WARN)
		return
	end
	
	-- 检查是否在SSH环境中
	if os.getenv('SSH_CLIENT') or os.getenv('SSH_TTY') then
		-- SSH环境下直接使用OSC52
		local text = content:gsub('\n$', '')
		local osc52 = string.format('\027]52;c;%s\007', vim.base64.encode(text))
		io.stdout:write(osc52)
		io.stdout:flush()
		vim.notify("已通过OSC52" .. notify_message, vim.log.levels.INFO)
	else
		-- 本地环境使用标准剪贴板
		vim.fn.setreg('+', content)
		vim.notify("已" .. notify_message, vim.log.levels.INFO)
	end
end

local function copy_message()
	local message = vim.fn.getreg("+")
	copy_to_clipboard(message, "复制消息内容到剪贴板")
end

local function copy_last_message()
	-- 获取最后一条消息
	local messages = vim.api.nvim_exec2("messages", {output = true})
	local lines = vim.split(messages.output, "\n")
	local last_message = ""
	
	-- 找到最后一条非空消息
	for i = #lines, 1, -1 do
		if lines[i] ~= "" then
			last_message = lines[i]
			break
		end
	end
	
	copy_to_clipboard(last_message, "复制最后一条消息到剪贴板")
end

local function copy_all_messages()
	-- 获取所有消息
	local messages = vim.api.nvim_exec2("messages", {output = true})
	local all_messages = messages.output
	
	copy_to_clipboard(all_messages, "复制所有消息到剪贴板")
end

local function copy_file_path()
	local file_path = vim.fn.expand('%:p')
	copy_to_clipboard(file_path, "复制文件路径到剪贴板: " .. file_path)
end

local function copy_word_with_location()
	-- 获取当前光标下的 word
	local word = vim.fn.expand('<cword>')
	-- 获取当前文件路径
	local file_path = vim.fn.expand('%:p')
	-- 获取当前行号
	local line_num = vim.fn.line('.')

	-- 格式: file_path:line_num:word
	local content = string.format("%s:%d:%s", file_path, line_num, word)

	copy_to_clipboard(content, "复制 word 和位置信息到剪贴板")
end

local function extract_path_with_line_at_cursor()
	local current_line = vim.api.nvim_get_current_line()
	local cursor_col = vim.api.nvim_win_get_cursor(0)[2] + 1
	local patterns = { "[^%s:]+:%d+:%d+", "[^%s:]+:%d+" }

	for _, pattern in ipairs(patterns) do
		local start_col = 1
		while true do
			local s, e = current_line:find(pattern, start_col)
			if not s then
				break
			end
			if cursor_col >= s and cursor_col <= e then
				return current_line:sub(s, e)
			end
			start_col = e + 1
		end
	end
end

local function resolve_path(base_path)
	if not base_path or base_path == "" then
		return nil
	end

	if base_path:sub(1, 1) == "~" then
		base_path = vim.fn.expand(base_path)
	end

	if base_path:match("^/") and vim.fn.filereadable(base_path) == 1 then
		return vim.fn.fnamemodify(base_path, ":p")
	end

	local project_root = get_project_root()
	if project_root and project_root ~= "" then
		local candidate = vim.fn.fnamemodify(project_root .. "/" .. base_path, ":p")
		if vim.fn.filereadable(candidate) == 1 then
			return candidate
		end
	end

	local current_dir = vim.fn.expand("%:p:h")
	if current_dir and current_dir ~= "" then
		local candidate = vim.fn.fnamemodify(current_dir .. "/" .. base_path, ":p")
		if vim.fn.filereadable(candidate) == 1 then
			return candidate
		end
	end

	local candidate = vim.fn.fnamemodify(vim.fn.getcwd() .. "/" .. base_path, ":p")
	if vim.fn.filereadable(candidate) == 1 then
		return candidate
	end

	return vim.fn.fnamemodify(base_path, ":p")
end

local function open_path_at_cursor()
	local match = extract_path_with_line_at_cursor()
	if not match then
		vim.notify("未在光标附近找到 path:line", vim.log.levels.WARN)
		return
	end

	match = match:gsub("[,.;]+$", "")
	local path_part, line_str, col_str = match:match("^([^:]+):(%d+):?(%d*)$")
	if not path_part or not line_str then
		vim.notify("无法解析路径: " .. match, vim.log.levels.WARN)
		return
	end

	local target_path = resolve_path(path_part)
	if not target_path or vim.fn.filereadable(target_path) == 0 then
		vim.notify("文件不存在: " .. (target_path or path_part), vim.log.levels.ERROR)
		return
	end

	vim.cmd("edit " .. vim.fn.fnameescape(target_path))
	local line_num = tonumber(line_str) or 1
	local col_num = tonumber(col_str)
	if col_num and col_num > 0 then
		vim.api.nvim_win_set_cursor(0, { line_num, col_num - 1 })
	else
		vim.api.nvim_win_set_cursor(0, { line_num, 0 })
	end
end

function M.setup()
	vim.keymap.set("n", "gF", open_path_at_cursor, { desc = "Open path:line under cursor" })

	local keymap = {
		{ "<leader>v", group = "Some Thing", nowait = false, remap = false },
		{ "<leader>vE", "<cmd>edit %<cr>", desc = "Reload Current File", nowait = false, remap = false },
		{ "<leader>va", "<cmd>qa<cr>", desc = "Exit", nowait = false, remap = false },
		{ "<leader>vb", "<cmd>%bd|e#<cr>", desc = "Delete Other Buffers", nowait = false, remap = false },
		{ "<leader>vc", "<cmd>DiffviewClose<cr>", desc = "Close Diff", nowait = false, remap = false },
		{ "<leader>vd", "<cmd>DiffviewOpen<cr>", desc = "Open Diff", nowait = false, remap = false },
		{ "<leader>ve", "<cmd>bufdo edit %<cr>", desc = "Reload All Buffer File", nowait = false, remap = false },
		{ "<leader>vf", "<cmd>ASToggle<cr>", desc = "Toggle Auto Save", nowait = false, remap = false },
		{ "<leader>vg", "<cmd>ToggleTermToggleAll<cr>", desc = "ToggleAllTerm", nowait = false, remap = false },
		{ "<leader>vh", toggle_hlsearch, desc = "Toggle Hlsearch", nowait = false, remap = false },
		{
			"<leader>vi",
			reload.reload_config,
			desc = "Reload Neovim Config",
			nowait = false,
			remap = false,
		},
		{ "<leader>vj", "<cmd>set relativenumber<cr>", desc = "Set Relative Number", nowait = false, remap = false },
		{
			"<leader>vk",
			"<cmd>set norelativenumber<cr>",
			desc = "Cancel Relative Number",
			nowait = false,
			remap = false,
		},
		{ "<leader>vlr", rename_current_file, desc = "Rname Current File", nowait = false, remap = false },
		{ "<leader>vla", create_new_file, desc = "Create New File", nowait = false, remap = false },
		{ "<leader>vm", ":%bd!|e#|bd#<cr>", desc = "Remove Other Buffer File", nowait = false, remap = false },
		{
			"<leader>vn",
			"<cmd>lua = vim.api.nvim_buf_get_name(0)<cr>",
			desc = "Get File Abs Path",
			nowait = false,
			remap = false,
		},
		{ "<leader>vo", "<cmd>only<cr>", desc = "Only Window", nowait = false, remap = false },
		{
			"<leader>vp",
			copy_file_path,
			desc = "Copy File Path to Clipboard",
			nowait = false,
			remap = false,
		},
		{ "<leader>vq", "<cmd>q<cr>", desc = "Close Current Tab", nowait = false, remap = false },
		{ "<leader>vr", "<cmd>LspRestart<cr>", desc = "Lsp Restart", nowait = false, remap = false },
		{ "<leader>vs", "<cmd>only<cr><cmd>tabo<cr>", desc = "Only Window Only Tab", nowait = false, remap = false },
		{ "<leader>vt", toggle_neovide, desc = "Toggle Neovide", nowait = false, remap = false },
		{ "<leader>vu", ":UndotreeToggle<cr>", desc = "Undo Tree Toggle", nowait = false, remap = false },
		{ "<leader>vv", open_project_in_new_tab, desc = "Open Project In New Tab", nowait = false, remap = false },
		{ "<leader>vw", ":DiffviewFileHistory %<cr>", desc = "File History", nowait = false, remap = false },
		{ "<leader>vy", "viw:Translate zh-CN<cr>", desc = "Translate", nowait = false, remap = false },
		{ "<leader>vz", ":ZenMode<cr>", desc = "Toggle Zen Mode", nowait = false, remap = false },
		{ "<leader>vx", copy_message, desc = "Copy Message Content", nowait = false, remap = false },
		{ "<leader>vxl", copy_last_message, desc = "Copy Last Message", nowait = false, remap = false },
		{ "<leader>vxa", copy_all_messages, desc = "Copy All Messages", nowait = false, remap = false },
		{ "<leader>vxw", copy_word_with_location, desc = "Copy Word with Location", nowait = false, remap = false },
		{ "<leader>vL", open_path_at_cursor, desc = "Open path:line under cursor", nowait = false, remap = false },
	}

	which_key.add(keymap)
end

return M
