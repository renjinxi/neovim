-- ================================
-- Flash 现代化移动插件配置 (2025年推荐，替代leap+flit)
-- ================================

local config = {
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
	-- 高亮配置 (针对 light 主题优化)
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

-- 为 light 主题设置优化的高亮组
local function setup_light_theme_highlights()
	-- 检查当前背景色
	local bg = vim.o.background
	
	-- 为 light 主题设置高亮组
	if bg == "light" then
		-- Flash 标签: 深色背景, 白色前景
		vim.api.nvim_set_hl(0, "FlashLabel", {
			fg = "#ffffff",
			bg = "#2563eb", -- 蓝色背景
			bold = true,
		})
		
		-- Flash 匹配: 深色背景, 浅色前景
		vim.api.nvim_set_hl(0, "FlashMatch", {
			fg = "#1f2937", -- 深灰色
			bg = "#fef3c7", -- 浅黄色背景
			bold = true,
		})
		
		-- Flash 当前项: 橙色背景
		vim.api.nvim_set_hl(0, "FlashCurrent", {
			fg = "#ffffff",
			bg = "#ea580c", -- 橙色背景
			bold = true,
		})
		
		-- Flash 背景: 轻微变暗
		vim.api.nvim_set_hl(0, "FlashBackdrop", {
			fg = "#6b7280", -- 灰色
		})
	else
		-- 保持深色主题的默认设置
		vim.api.nvim_set_hl(0, "FlashLabel", {
			fg = "#ffffff",
			bg = "#ff007c",
			bold = true,
		})
		
		vim.api.nvim_set_hl(0, "FlashMatch", {
			fg = "#c0caf5",
			bg = "#3d59a1",
			bold = true,
		})
		
		vim.api.nvim_set_hl(0, "FlashCurrent", {
			fg = "#ffffff",
			bg = "#ff9e64",
			bold = true,
		})
		
		vim.api.nvim_set_hl(0, "FlashBackdrop", {
			fg = "#545c7e",
		})
	end
end

-- 设置自动命令，在主题切换时重新设置高亮
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = setup_light_theme_highlights,
})

-- 初始化时设置高亮
setup_light_theme_highlights()

return config