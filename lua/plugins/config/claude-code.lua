-- claude-code.nvim 配置
-- 提供 Neovim 与 Claude Code AI 助手的无缝集成

require("claude-code").setup({
	-- 终端窗口设置
	window = {
		split_ratio = 0.4, -- 终端窗口占屏幕的百分比（水平分割为高度，垂直分割为宽度）
		position = "vertical", -- 窗口位置："botright", "topleft", "vertical", "float" 等
		enter_insert = true, -- 打开 Claude Code 时是否进入插入模式
		hide_numbers = true, -- 在终端窗口中隐藏行号
		hide_signcolumn = true, -- 在终端窗口中隐藏符号列

		-- 浮动窗口配置（仅在 position = "float" 时适用）
		float = {
			width = "85%", -- 宽度：列数或百分比字符串
			height = "85%", -- 高度：行数或百分比字符串
			row = "center", -- 行位置：数字、"center" 或百分比字符串
			col = "center", -- 列位置：数字、"center" 或百分比字符串
			relative = "editor", -- 相对于："editor" 或 "cursor"
			border = "rounded", -- 边框样式："none", "single", "double", "rounded", "solid", "shadow"
		},
	},

	-- 文件刷新设置
	refresh = {
		enable = true, -- 启用文件更改检测
		updatetime = 100, -- Claude Code 活动时的更新时间（毫秒）
		timer_interval = 1000, -- 检查文件更改的频率（毫秒）
		show_notifications = true, -- 文件重新加载时显示通知
	},

	-- Git 项目设置
	git = {
		use_git_root = true, -- 打开 Claude Code 时设置当前工作目录为 git 根目录（如果在 git 项目中）
	},

	-- Shell 特定设置
	shell = {
		separator = "&&", -- Shell 命令中使用的命令分隔符
		pushd_cmd = "pushd", -- 推入目录到栈的命令（如 bash/zsh 的 'pushd'，nushell 的 'enter'）
		popd_cmd = "popd", -- 从栈弹出目录的命令（如 bash/zsh 的 'popd'，nushell 的 'exit'）
	},

	-- 命令设置
	command = "claude", -- 启动 Claude Code 的命令

	-- 命令变体
	command_variants = {
		-- 对话管理
		continue = "--continue", -- 恢复最近的对话
		resume = "--resume", -- 显示交互式对话选择器

		-- 输出选项
		verbose = "--verbose", -- 启用详细日志记录，包含完整的回合输出
	},

	-- 按键映射
	keymaps = {
		toggle = {
			normal = "<C-,>", -- 普通模式下切换 Claude Code 的按键映射，设为 false 禁用
			terminal = "<C-,>", -- 终端模式下切换 Claude Code 的按键映射，设为 false 禁用
			variants = {
				continue = "<leader>cC", -- 普通模式下使用 continue 标志启动 Claude Code
				verbose = "<leader>cV", -- 普通模式下使用 verbose 标志启动 Claude Code
			},
		},
		window_navigation = true, -- 启用窗口导航按键映射（<C-h/j/k/l>）
		scrolling = true, -- 启用滚动按键映射（<C-f/b>）用于翻页
	},
}) 