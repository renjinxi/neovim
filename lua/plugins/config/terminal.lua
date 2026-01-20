-- Terminal 模式的 buffer-local keymaps (必须通过 TermOpen autocmd 设置)
function _G.set_terminal_keymaps()
	local opts = { buffer = 0 }
	vim.keymap.set("t", "[[", [[<C-\><C-n>]], opts)
	vim.keymap.set("t", "【【", [[<C-\><C-n>]], opts)
	vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
	vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
	vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
	vim.keymap.set("t", "<C-'>", function()
		vim.cmd([[stopinsert]])
		vim.schedule(function()
			local half_page = math.floor(vim.api.nvim_win_get_height(0) / 2)
			vim.cmd("normal! " .. half_page .. "k")
		end)
	end, opts)
	vim.keymap.set("t", "gt", [[<C-\><C-n>gt]], opts)
	vim.keymap.set("t", "gT", [[<C-\><C-n>gT]], opts)
	-- Ctrl+数字 切换 Tab
	for i = 1, 9 do
		vim.keymap.set("t", "<C-" .. i .. ">", [[<C-\><C-n>]] .. i .. [[gt]], opts)
	end
end

vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
