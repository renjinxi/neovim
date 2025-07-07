-- claude-code.nvim 按键映射配置
-- 提供 Claude Code AI 助手的快捷键设置

local M = {}

function M.setup()
	-- 基本快捷键映射
	vim.keymap.set("n", "<leader>cc", "<cmd>ClaudeCode<CR>", { 
		desc = "切换 Claude Code 终端" 
	})
	
	-- 对话管理命令
	vim.keymap.set("n", "<leader>cC", "<cmd>ClaudeCodeContinue<CR>", { 
		desc = "恢复最近的 Claude Code 对话" 
	})
	
	vim.keymap.set("n", "<leader>cr", "<cmd>ClaudeCodeResume<CR>", { 
		desc = "显示 Claude Code 对话选择器" 
	})
	
	-- 输出选项
	vim.keymap.set("n", "<leader>cV", "<cmd>ClaudeCodeVerbose<CR>", { 
		desc = "启用详细日志的 Claude Code" 
	})
	
	-- 快速发送并返回插入模式
	vim.keymap.set("i", "<C-s>", "<cmd>ClaudeCodeSendAndInsert<CR>", { 
		desc = "发送到 Claude Code 并返回插入模式" 
	})
	
	-- 消息导航
	vim.keymap.set("n", "]c", "<cmd>ClaudeCodeNextMessage<CR>", { 
		desc = "跳转到下一条 Claude Code 消息" 
	})
	
	vim.keymap.set("n", "[c", "<cmd>ClaudeCodePrevMessage<CR>", { 
		desc = "跳转到上一条 Claude Code 消息" 
	})
	
	-- 取消当前请求
	vim.keymap.set("n", "<leader>cx", "<cmd>ClaudeCodeCancel<CR>", { 
		desc = "取消当前 Claude Code 请求" 
	})
	
	-- 重新显示上次通知
	vim.keymap.set("n", "<leader>cn", "<cmd>ClaudeCodeRecallNotification<CR>", { 
		desc = "重新显示上次 Claude Code 通知" 
	})
	
	-- 日志管理
	vim.keymap.set("n", "<leader>cel", "<cmd>ClaudeCodeEnableLogging<CR>", { 
		desc = "启用 Claude Code 日志记录" 
	})
	
	vim.keymap.set("n", "<leader>cdl", "<cmd>ClaudeCodeDisableLogging<CR>", { 
		desc = "禁用 Claude Code 日志记录" 
	})
	
	vim.keymap.set("n", "<leader>col", "<cmd>ClaudeCodeOpenLog<CR>", { 
		desc = "打开 Claude Code 日志文件" 
	})
	
	-- 导入命令
	vim.keymap.set("n", "<leader>ci", "<cmd>ClaudeCodeImport<CR>", { 
		desc = "导入 Claude Workbench 对话" 
	})
	
	-- 替代快捷键（与配置文件中的快捷键保持一致）
	vim.keymap.set("n", "<C-,>", "<cmd>ClaudeCode<CR>", { 
		desc = "切换 Claude Code 终端" 
	})
	
	vim.keymap.set("t", "<C-,>", "<cmd>ClaudeCode<CR>", { 
		desc = "切换 Claude Code 终端" 
	})
end

return M 