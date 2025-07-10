-- claude-code.nvim 按键映射配置
-- 提供 Claude Code AI 助手的快捷键设置

local M = {}

function M.setup()
	local keymap = {
		{ "<leader>c", group = "Claude Code", nowait = false, remap = false },
		{
			"<leader>cc",
			"<cmd>ClaudeCode<CR>",
			desc = "切换 Claude Code 终端",
			nowait = false,
			remap = false,
		},
		{
			"<leader>cC",
			"<cmd>ClaudeCodeContinue<CR>",
			desc = "恢复最近的 Claude Code 对话",
			nowait = false,
			remap = false,
		},
		{
			"<leader>cr",
			"<cmd>ClaudeCodeResume<CR>",
			desc = "显示 Claude Code 对话选择器",
			nowait = false,
			remap = false,
		},
		{
			"<leader>cV",
			"<cmd>ClaudeCodeVerbose<CR>",
			desc = "启用详细日志的 Claude Code",
			nowait = false,
			remap = false,
		},
		{
			"<leader>cx",
			"<cmd>ClaudeCodeCancel<CR>",
			desc = "取消当前 Claude Code 请求",
			nowait = false,
			remap = false,
		},
		{
			"<leader>cn",
			"<cmd>ClaudeCodeRecallNotification<CR>",
			desc = "重新显示上次 Claude Code 通知",
			nowait = false,
			remap = false,
		},
		{
			"<leader>ci",
			"<cmd>ClaudeCodeImport<CR>",
			desc = "导入 Claude Workbench 对话",
			nowait = false,
			remap = false,
		},
		-- 日志管理子组
		{ "<leader>ce", group = "日志管理", nowait = false, remap = false },
		{
			"<leader>cel",
			"<cmd>ClaudeCodeEnableLogging<CR>",
			desc = "启用 Claude Code 日志记录",
			nowait = false,
			remap = false,
		},
		{
			"<leader>cdl",
			"<cmd>ClaudeCodeDisableLogging<CR>",
			desc = "禁用 Claude Code 日志记录",
			nowait = false,
			remap = false,
		},
		{
			"<leader>col",
			"<cmd>ClaudeCodeOpenLog<CR>",
			desc = "打开 Claude Code 日志文件",
			nowait = false,
			remap = false,
		},
	}
	
	-- 消息导航键映射
	local navigation_keymap = {
		{
			"]c",
			"<cmd>ClaudeCodeNextMessage<CR>",
			desc = "跳转到下一条 Claude Code 消息",
			nowait = false,
			remap = false,
		},
		{
			"[c",
			"<cmd>ClaudeCodePrevMessage<CR>",
			desc = "跳转到上一条 Claude Code 消息",
			nowait = false,
			remap = false,
		},
		{
			"<C-,>",
			"<cmd>ClaudeCode<CR>",
			desc = "切换 Claude Code 终端",
			nowait = false,
			remap = false,
			mode = "n",
		},
		{
			"<C-,>",
			"<cmd>ClaudeCode<CR>",
			desc = "切换 Claude Code 终端",
			nowait = false,
			remap = false,
			mode = "t",
		},
	}
	
	-- 插入模式键映射
	local insert_keymap = {
		{
			"<C-s>",
			"<cmd>ClaudeCodeSendAndInsert<CR>",
			desc = "发送到 Claude Code 并返回插入模式",
			nowait = false,
			remap = false,
			mode = "i",
		},
	}
	
	require("which-key").add(keymap)
	require("which-key").add(navigation_keymap)
	require("which-key").add(insert_keymap)
end

return M 