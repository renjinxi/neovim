return {
	window = {
		-- backdrop = 0.85, -- 更明显的背景遮罩，让边界更清楚
		width = 1, -- 使用百分比，让窗口更小，与背景区分更明显
		height = 1,
		options = {
			signcolumn = "no", -- 隐藏标志列
			number = false, -- 隐藏行号
			relativenumber = false, -- 隐藏相对行号
			cursorline = false, -- 隐藏光标行高亮
			cursorcolumn = false, -- 隐藏光标列
			foldcolumn = "0", -- 隐藏折叠列
			list = false, -- 隐藏空白字符
		},
	},
	plugins = {
		options = {
			enabled = true,
			ruler = false, -- 禁用标尺
			showcmd = false, -- 禁用命令显示
			laststatus = 0, -- 关闭状态栏
		},
		twilight = { enabled = false }, -- 禁用twilight以避免冲突
		gitsigns = { enabled = false }, -- 禁用git标志
		tmux = { enabled = false },
		kitty = { enabled = false },
		alacritty = { enabled = false },
		wezterm = { enabled = false },
	},
	-- 进入zen模式时的回调
	on_open = function(win)
		-- 禁用当前缓冲区的诊断显示
		vim.diagnostic.config({
			virtual_text = false,
			signs = false,
			underline = false,
			update_in_insert = false,
		})
	end,
	-- 退出zen模式时的回调
	on_close = function()
		-- 恢复诊断显示，包括图标配置
		vim.diagnostic.config({
			virtual_text = false, -- 保持与 LSP 配置一致
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = "󰅚",
					[vim.diagnostic.severity.WARN] = "󰀪",
					[vim.diagnostic.severity.HINT] = "󰌶", 
					[vim.diagnostic.severity.INFO] = "●",
				},
			},
			underline = true,
			update_in_insert = false,
			severity_sort = true,
		})
	end,
}

