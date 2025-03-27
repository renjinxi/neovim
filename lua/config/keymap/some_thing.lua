local status_ok, which_key = pcall(require, "which-key")
if not status_ok then
	return
end

local normal_opts = {
	mode = "n",
	prefix = "<leader>",
	buffer = nil,
	silent = true,
	noremap = true,
	nowait = false,
}

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
		vim.api.nvim_command("e " .. new_path)
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
		vim.api.nvim_command("e " .. new_path)
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

local function copy_messages()
	-- 获取消息历史
	local messages = vim.fn.execute('messages')
	-- 复制到系统剪贴板
	vim.fn.setreg('+', messages)
	print("Messages copied to clipboard")
end

local function copy_last_error()
	-- 获取最后一条错误消息
	local error_msg = vim.v.errmsg
	-- 复制到系统剪贴板
	vim.fn.setreg('+', error_msg)
	print("Last error message copied to clipboard")
end

local keymap = {
	-- 消息和错误处理
	{ "<leader>m", group = "Messages", nowait = false, remap = false },
	{ "<leader>ms", ":messages<cr>", desc = "Show Message History", nowait = false, remap = false },
	{ "<leader>mc", ":messages clear<cr>", desc = "Clear Message History", nowait = false, remap = false },
	{ "<leader>me", ":echo v:errmsg<cr>", desc = "Show Last Error", nowait = false, remap = false },
	{ "<leader>my", copy_messages, desc = "Copy All Messages", nowait = false, remap = false },
	{ "<leader>mx", copy_last_error, desc = "Copy Last Error", nowait = false, remap = false },
	
	-- 配置相关
	{ "<leader>c", group = "Config Operations", nowait = false, remap = false },
	{ "<leader>cr", function() require("config.reload").reload_config() end, desc = "Reload Config", nowait = false, remap = false },
	
	-- 编辑器功能切换
	{ "<leader>e", group = "Editor Toggles", nowait = false, remap = false },
	{ "<leader>eh", toggle_hlsearch, desc = "Toggle Search Highlight", nowait = false, remap = false },
	{ "<leader>en", "<cmd>set relativenumber!<cr>", desc = "Toggle Relative Number", nowait = false, remap = false },
	{ "<leader>es", "<cmd>ASToggle<cr>", desc = "Toggle Auto Save", nowait = false, remap = false },
	{ "<leader>et", "<cmd>ToggleTermToggleAll<cr>", desc = "Toggle All Terms", nowait = false, remap = false },
	{ "<leader>eu", ":UndotreeToggle<cr>", desc = "Toggle Undotree", nowait = false, remap = false },
	{ "<leader>ez", ":ZenMode<cr>", desc = "Toggle Zen Mode", nowait = false, remap = false },
	
	-- 版本控制
	{ "<leader>v", group = "Version Control", nowait = false, remap = false },
	{ "<leader>vd", "<cmd>DiffviewOpen<cr>", desc = "Open Diff View", nowait = false, remap = false },
	{ "<leader>vc", "<cmd>DiffviewClose<cr>", desc = "Close Diff View", nowait = false, remap = false },
	
	-- 其他功能
	{ "<leader>y", "viw:Translate zh-CN<cr>", desc = "Translate Word", nowait = false, remap = false },
	{ "<leader>q", "<cmd>q<cr>", desc = "Close Window", nowait = false, remap = false },
	{ "<leader>Q", "<cmd>qa<cr>", desc = "Exit Neovim", nowait = false, remap = false },
}

which_key.add(keymap)
