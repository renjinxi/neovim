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
	-- 询问新文件名
	local new_name = vim.fn.input("New Name: ", vim.fn.expand("%:t"), "file")
	if new_name == "" then
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

local keymap = {
	v = {
		name = "Some Thing",
		--l = { "<cmd>noh<cr>", "Cachel HighLight" },
		E = { "<cmd>edit %<cr>", "Reload Current File" },

		a = { "<cmd>qa<cr>", "Exit" },
		b = { "<cmd>%bd|e#<cr>", "Delete Other Buffers" },
		c = { "<cmd>DiffviewClose<cr>", "Close Diff" },
		d = { "<cmd>DiffviewOpen<cr>", "Open Diff" },
		e = { "<cmd>bufdo edit %<cr>", "Reload All Buffer File" },
		f = { "<cmd>ASToggle<cr>", "Toggle Auto Save" },
		g = { "<cmd>ToggleTermToggleAll<cr>", "ToggleAllTerm" },
		h = { "<cmd>SymbolsOutline<cr>", "Toggle Symbols" },
		i = { "<cmd>luafile ~/.config/nvim/init.lua<cr><cmd>Lazy restore<cr>", "reload config" },
		j = { "<cmd>set relativenumber<cr>", "Set Relative Number" },
		k = { "<cmd>set norelativenumber<cr>", "Cancel Relative Number" },
		l = { rename_current_file, "Rname Current File" },
		m = { ":%bd!|e#|bd#<cr>", "Remove Other Buffer File" },
		n = { "<cmd>lua = vim.api.nvim_buf_get_name(0)<cr>", "Get File Abs Path" },
		o = { "<cmd>only<cr>", "Only Window" },
		p = { ":lua vim.fn.setreg('+', vim.fn.expand('%:p'))<CR>", "Copy File Path to Clipboard" },
		q = { "<cmd>q<cr>", "Close Current Tab" },
		r = { "<cmd>LspRestart<cr>", "Lsp Restart" },
		s = { "<cmd>only<cr><cmd>tabo<cr>", "Only Window Only Tab" },
		t = { toggle_neovide, "Toggle Neovide" },
		-- u = { "<cmd>TroubleToggle<cr>", "Trouble Toggle" },
		v = { open_project_in_new_tab, "Open Project In New Tab" },
		w = { ":DiffviewFileHistory %<cr>", "File History" },
		z = { ":ZenMode<cr>", "Toggle Zen Mode" },
	},
}
which_key.register(keymap, normal_opts)
