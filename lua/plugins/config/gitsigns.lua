local M = {}

function M.setup()
	require("gitsigns").setup({
		signs = {
			add = {
				text = "█",
				hl = "GitSignsAdd",
				linehl = "GitSignsAddLn",
				numhl = "GitSignsAddNr",
			},
			change = {
				text = "█",
				hl = "GitSignsChange",
				linehl = "GitSignsChangeLn",
				numhl = "GitSignsChangeNr",
			},
			delete = {
				text = "█",
				hl = "GitSignsDelete",
				linehl = "GitSignsDeleteLn",
				numhl = "GitSignsDeleteNr",
			},
			topdelete = {
				text = "█",
				hl = "GitSignsDelete",
				linehl = "GitSignsDeleteLn",
				numhl = "GitSignsDeleteNr",
			},
			changedelete = {
				text = "█",
				hl = "GitSignsChangeDelete",
				linehl = "GitSignsChangeDeleteLn",
				numhl = "GitSignsChangeDeleteNr",
			},
		},

		-- 使用 Rose Pine 颜色主题
		on_attach = function(bufnr)
			-- 避免在非git仓库中出错
			if not vim.b[bufnr].gitsigns_status_dict then
				return false
			end

			-- 获取 Rose Pine 调色板（带回退）
			local ok, palette = pcall(require, "rose-pine.palette")
			if not ok then
				-- 回退颜色
				palette = {
					foam = "#9ccfd8",
					rose = "#ebbcba",
					love = "#eb6f92",
					pine = "#31748f",
					surface = "#1f1d2e",
				}
			end

			-- 使用 Rose Pine 的 git 颜色（深色版本让标记更明显）
			local foam_dark = "#4a9aa1" -- 更深的 foam
			local rose_dark = "#c7956b" -- 更深的 rose
			local love_dark = "#c85578" -- 更深的 love
			local pine_dark = "#26627a" -- 更深的 pine

			vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = foam_dark, bg = "NONE", bold = true })
			vim.api.nvim_set_hl(0, "GitSignsChange", { fg = rose_dark, bg = "NONE", bold = true })
			vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = love_dark, bg = "NONE", bold = true })
			vim.api.nvim_set_hl(0, "GitSignsChangeDelete", { fg = pine_dark, bg = "NONE", bold = true })

			-- 可选的行高亮（使用 Rose Pine 的柔和背景色）
			vim.api.nvim_set_hl(0, "GitSignsAddLn", { bg = palette.surface })
			vim.api.nvim_set_hl(0, "GitSignsChangeLn", { bg = palette.surface })
			vim.api.nvim_set_hl(0, "GitSignsDeleteLn", { bg = palette.surface })
			vim.api.nvim_set_hl(0, "GitSignsChangeDeleteLn", { bg = palette.surface })

			-- 行号高亮（使用对应的深色 Rose Pine 颜色）
			vim.api.nvim_set_hl(0, "GitSignsAddNr", { fg = foam_dark, bold = true })
			vim.api.nvim_set_hl(0, "GitSignsChangeNr", { fg = rose_dark, bold = true })
			vim.api.nvim_set_hl(0, "GitSignsDeleteNr", { fg = love_dark, bold = true })
			vim.api.nvim_set_hl(0, "GitSignsChangeDeleteNr", { fg = pine_dark, bold = true })
		end,

		-- 配置选项
		signcolumn = true, -- 显示标记列
		numhl = false, -- 高亮行号
		linehl = false, -- 高亮整行（默认关闭，可以通过命令切换）
		word_diff = false, -- 词级别差异

		watch_gitdir = {
			follow_files = true,
		},

		auto_attach = true,
		attach_to_untracked = false,

		current_line_blame = false, -- 当前行 blame（默认关闭）
		current_line_blame_opts = {
			virt_text = true,
			virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
			delay = 1000,
			ignore_whitespace = false,
		},
		current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",

		sign_priority = 6,
		update_debounce = 100,
		status_formatter = nil, -- Use default
		max_file_length = 40000, -- Disable if file is longer than this (in lines)

		preview_config = {
			-- Options passed to nvim_open_win
			border = "single",
			style = "minimal",
			relative = "cursor",
			row = 0,
			col = 1,
		},
		-- Keymaps (可以在这里定义，也可以在单独的键位映射文件中定义)
		-- 这里留空，使用外部键位映射文件
	})
end

-- 直接调用设置
M.setup()

return M
