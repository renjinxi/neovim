function _G.set_terminal_keymaps()
	local opts = { buffer = 0 }
	-- vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts) -- 注释掉让ESC发送给终端
	vim.keymap.set("t", "[[", [[<C-\><C-n>]], opts)
	vim.keymap.set("t", "【【", [[<C-\><C-n>]], opts)
	vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
	vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
	vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
	vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
	-- 在终端模式下也能使用gt切换标签页并切换到normal模式
	vim.keymap.set("t", "gt", [[<C-\><C-n>gt]], opts)
	-- 在终端模式下也能使用gT切换到上一个标签页并切换到normal模式
	vim.keymap.set("t", "gT", [[<C-\><C-n>gT]], opts)

	-- 在终端模式下使用Ctrl+数字切换到对应标签页并切换到normal模式
	for i = 1, 9 do
		vim.keymap.set("t", "<C-" .. i .. ">", [[<C-\><C-n>]] .. i .. [[gt]], opts)
	end
end

-- Apply terminal keymaps when terminal opens
vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")

require("toggleterm").setup({
	size = function(term)
		if term.direction == "horizontal" then
			return 20
		elseif term.direction == "vertical" then
			return math.floor(vim.o.columns * 0.4)
		end
	end,
	open_mapping = [[<c-\>]],
	hide_numbers = false,
	shade_filetypes = {},
	shading_factor = 2,
	start_in_insert = true,
	shade_terminals = false,
	insert_mappings = true,
	persist_size = true,
	direction = "horizontal",
	close_on_exit = true,
	shell = vim.o.shell,

	--background = "Normal",
	float_opts = {
		border = "curved",
		winblend = 0,
		highlights = {
			border = "Normal",
			background = "Normal",
		},
	},
})
