function _G.set_terminal_keymaps()
	local opts = { buffer = 0 }
	-- vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts) -- 注释掉让ESC发送给终端
	vim.keymap.set("t", "[[", [[<C-\><C-n>]], opts)
	vim.keymap.set("t", "【【", [[<C-\><C-n>]], opts)
	vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
	vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
	-- vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts) -- 注释掉以便 <C-k> 用于切换所有终端
	vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
	-- 在终端模式中按 Ctrl+': 先进入 normal 模式，然后向上翻页半屏
	vim.keymap.set("t", "<C-'>", function()
		-- 先退出 terminal insert 模式
		vim.cmd([[stopinsert]])
		-- 延迟执行滚动
		vim.schedule(function()
			-- 获取窗口高度的一半
			local half_page = math.floor(vim.api.nvim_win_get_height(0) / 2)
			-- 向上滚动
			vim.cmd("normal! " .. half_page .. "k")
		end)
	end, opts)
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
