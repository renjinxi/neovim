local M = {}
local status_ok, which_key = pcall(require, "which-key")
if not status_ok then
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

function M.setup()
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
		"<cmd>luafile ~/.config/nvim/init.lua<cr><cmd>Lazy restore<cr>",
		desc = "reload config",
		nowait = false,
		remap = false,
	},
	{ "<leader>vj", "<cmd>set relativenumber<cr>", desc = "Set Relative Number", nowait = false, remap = false },
	{ "<leader>vk", "<cmd>set norelativenumber<cr>", desc = "Cancel Relative Number", nowait = false, remap = false },
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
		":lua vim.fn.setreg('+', vim.fn.expand('%:p'))<CR>",
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
	}
	which_key.add(keymap)
end

return M