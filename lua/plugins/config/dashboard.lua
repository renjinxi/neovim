-- ================================
-- Dashboard 启动屏配置 (2025年现代化版本)
-- ================================

require("dashboard").setup({
	theme = "hyper", -- doom, hyper
	shortcut_type = "letter", -- letter, number
	hide = {
		statusline = true,
		tabline = true,
		winbar = true,
	},
	config = {
		header = {
			"",
			"███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
			"████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
			"██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
			"██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
			"██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
			"╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
			"",
			"🚀 Happy Coding! 🚀",
			"",
		},
		-- 快捷键配置
		shortcut = {
			{
				desc = "󰊳 Update",
				group = "@property",
				action = "Lazy update",
				key = "u",
			},
			{
				desc = " Files",
				group = "Label",
				action = "Telescope find_files",
				key = "f",
			},
			{
				desc = " Apps",
				group = "DiagnosticHint",
				action = "Telescope app",
				key = "a",
			},
			{
				desc = " dotfiles",
				group = "Number",
				action = "Telescope dotfiles",
				key = "d",
			},
		},
		-- 页脚
		footer = function()
			local stats = require("lazy").stats()
			local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
			return {
				"⚡ Neovim loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms",
			}
		end,
		-- 项目配置
		project = {
			enable = true,
			limit = 8,
			icon = "🗂️ ",
			label = " Recent Projects:",
			action = "Telescope find_files cwd=",
		},
		-- 最近文件
		mru = {
			limit = 10,
			icon = "📄 ",
			label = " Recent Files:",
			cwd_only = true, -- 只显示当前目录下的最近文件
		},
	},
}) 