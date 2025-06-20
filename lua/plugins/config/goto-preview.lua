-- ================================
-- Goto Preview 配置 (LSP 预览窗口)
-- ================================

local post_open_hook = function(_, win)
	-- 使用新的 API 替代已弃用的 nvim_win_set_option
	vim.wo[win].winhighlight = "Normal:"
end

require("goto-preview").setup({
	width = 120, -- 预览窗口宽度
	height = 25, -- 预览窗口高度
	border = { "↖", "─", "┐", "│", "┘", "─", "└", "│" }, -- 窗口边框
	default_mappings = false, -- 禁用默认映射，使用自定义键位
	debug = false, -- 调试模式
	opacity = nil, -- 透明度 (0-100)
	resizing_mappings = false, -- 禁用窗口大小调整映射
	post_open_hook = post_open_hook, -- 窗口打开后的钩子函数
	post_close_hook = nil, -- 窗口关闭后的钩子函数
	references = {
		telescope = require("telescope.themes").get_dropdown({ hide_preview = false })
	},
	-- 按文件类型配置不同行为
	focus_on_open = true, -- 打开时聚焦预览窗口
	dismiss_on_move = false, -- 移动光标时关闭预览
	force_close = true, -- 强制关闭
	bufhidden = "wipe", -- 缓冲区隐藏行为
	stack_floating_preview_windows = true, -- 堆叠浮动预览窗口
	preview_window_title = {
		enable = true,
		position = "left"
	},
}) 