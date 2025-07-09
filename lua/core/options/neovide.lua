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
	vim.g.neovide_opacity = 1.0
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
	local opts = { noremap = true, silent = true }
	
	-- 基本快捷键
	keymap("n", "<D-s>", ":w<CR>", opts) -- Save
	keymap("v", "<D-c>", '"+y', opts) -- Copy
	keymap("n", "<D-v>", '"+P', opts) -- Paste normal mode
	keymap("v", "<D-v>", '"+P', opts) -- Paste visual mode
	keymap("c", "<D-v>", "<C-R>+", opts) -- Paste command mode
	keymap("i", "<D-v>", '<ESC>l"+Pli', opts) -- Paste insert mode
	
	-- 终端模式特殊处理 - CMD+V 退出终端模式粘贴后重新进入
	keymap("t", "<D-v>", '<C-\\><C-n>"+pi', opts) -- Terminal paste with CMD+V
end

return M
