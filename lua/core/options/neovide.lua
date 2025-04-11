local M = {}

function M.setup()
	-- 字体设置
	vim.o.guifont = "Hack Nerd Font:h20"

	-- Neovide 特定设置
	vim.g.neovide_fullscreen = true
	vim.g.neovide_floating_shadow = false
	vim.g.neovide_input_macos_option_key_is_meta = "both"
	
	-- 禁用所有可能影响浮动窗口的特效
	vim.g.neovide_floating_blur_amount_x = 0
	vim.g.neovide_floating_blur_amount_y = 0
	vim.g.neovide_transparency = 1.0
	vim.g.neovide_floating_z_height = 0
	vim.g.neovide_window_floating_opacity = 1.0
	vim.g.neovide_window_floating_blur = false
	vim.g.neovide_floating_shadow = false
	vim.g.neovide_scroll_animation_length = 0
	vim.g.neovide_cursor_animation_length = 0
	vim.g.neovide_cursor_trail_size = 0
	vim.g.neovide_cursor_antialiasing = false
	vim.g.neovide_padding_top = 0
	vim.g.neovide_padding_bottom = 0
	vim.g.neovide_padding_right = 0
	vim.g.neovide_padding_left = 0

	-- macOS 特定快捷键
	local keymap = vim.keymap.set
	keymap("n", "<D-s>", ":w<CR>") -- Save
	keymap("v", "<D-c>", '"+y') -- Copy
	keymap("n", "<D-v>", '"+P') -- Paste normal mode
	keymap("v", "<D-v>", '"+P') -- Paste visual mode
	keymap("c", "<D-v>", "<C-R>+") -- Paste command mode
	keymap("i", "<D-v>", '<ESC>l"+Pli') -- Paste insert mode

	-- 剪贴板集成
	local function set_keymap(mode, lhs, rhs, opts)
		vim.api.nvim_set_keymap(mode, lhs, rhs, opts or { noremap = true, silent = true })
	end

	set_keymap("", "<D-v>", "+p<CR>")
	set_keymap("!", "<D-v>", "<C-R>+")
	set_keymap("t", "<D-v>", "<C-o>p")
	set_keymap("v", "<D-v>", "<C-R>+")
end

return M
