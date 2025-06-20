-- ================================
-- Flash 现代化移动插件配置 (2025年推荐，替代leap+flit)
-- ================================

return {
	-- 搜索配置
	search = {
		-- 搜索时向前和向后查找
		forward = true,
		-- 多窗口搜索
		multi_window = true,
		-- 环绕搜索
		wrap = true,
		-- 增量搜索
		incremental = false,
	},
	-- 跳转配置
	jump = {
		-- 自动跳转到唯一匹配
		jumplist = true,
		-- 跳转位置
		pos = "start", -- "start", "end", "range"
		-- 历史记录
		history = false,
		-- 寄存器
		register = false,
	},
	-- 标签配置
	label = {
		-- 标签字符
		alphabet = "abcdefghijklmnopqrstuvwxyz",
		-- 大写字符处理
		uppercase = true,
		-- 彩虹标签
		rainbow = {
			enabled = false,
			-- 仅在深色背景下启用
			shade = 5,
		},
	},
	-- 高亮配置
	highlight = {
		-- 高亮匹配
		matches = true,
		-- 背景高亮
		backdrop = true,
		-- 组
		groups = {
			match = "FlashMatch",
			current = "FlashCurrent",
			backdrop = "FlashBackdrop",
			label = "FlashLabel",
		},
	},
	-- 模式配置
	modes = {
		-- 字符模式 (类似 f, F, t, T)
		char = {
			enabled = true,
			-- 按键映射
			keys = { "f", "F", "t", "T", ";", "," },
			-- 搜索字符
			search = { wrap = false },
			-- 高亮
			highlight = { backdrop = true },
			-- 跳转
			jump = { register = false },
		},
		-- 搜索模式 (类似 /, ?)
		search = {
			enabled = true,
			-- 高亮
			highlight = { backdrop = false },
			-- 跳转
			jump = { history = true, register = true, nohlsearch = true },
			-- 搜索
			search = {
				-- 模式
				mode = "exact",
				-- 增量搜索
				incremental = true,
			},
		},
		-- Treesitter 搜索
		treesitter = {
			labels = "abcdefghijklmnopqrstuvwxyz",
			jump = { pos = "range" },
			search = { incremental = false },
			label = { before = true, after = true, style = "inline" },
			highlight = {
				backdrop = false,
				matches = false,
			},
		},
	},
}