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

local function rename_current_file()
	-- 获取当前文件的完整路径
	local old_path = vim.fn.expand("%:p")
	local current_buffer_name = vim.fn.expand("%:t")

	-- 使用 vim.ui.input 询问新文件名
	vim.ui.input({
		prompt = "New Name: ",
		default = current_buffer_name,
	}, function(new_name)
		if not new_name or new_name == "" then
			print("Rename cancelled.")
			return
		end

		-- 构建新的文件路径
		local new_path = vim.fn.fnamemodify(old_path, ":h") .. "/" .. new_name

		-- 重命名文件
		local success, err = os.rename(old_path, new_path)
		if not success then
			print("Error renaming file: " .. err)
			return
		end

		-- 更新当前缓冲区的文件路径
		vim.api.nvim_command("e " .. new_path)
		print("File renamed to " .. new_name)
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
	{ "<leader>vl", rename_current_file, desc = "Rname Current File", nowait = false, remap = false },
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
	{ "<leader>vv", open_project_in_new_tab, desc = "Open Project In New Tab", nowait = false, remap = false },
	{ "<leader>vw", ":DiffviewFileHistory %<cr>", desc = "File History", nowait = false, remap = false },
	{ "<leader>vz", ":ZenMode<cr>", desc = "Toggle Zen Mode", nowait = false, remap = false },
}
which_key.add(keymap)
