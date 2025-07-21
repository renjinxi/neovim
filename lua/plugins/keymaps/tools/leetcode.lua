-- leetcode.nvim 按键映射配置
-- 提供 LeetCode 算法练习的快捷键设置

local M = {}

function M.setup()
	local keymap = {
		{ "<leader>l", group = "LeetCode", nowait = false, remap = false },
		{
			"<leader>ll",
			"<cmd>Leet<CR>",
			desc = "打开 LeetCode 仪表板",
			nowait = false,
			remap = false,
		},
		{
			"<leader>lm",
			"<cmd>Leet menu<CR>",
			desc = "打开 LeetCode 菜单",
			nowait = false,
			remap = false,
		},
		{
			"<leader>lq",
			"<cmd>Leet list<CR>",
			desc = "浏览题目列表",
			nowait = false,
			remap = false,
		},
		{
			"<leader>lr",
			"<cmd>Leet random<CR>",
			desc = "打开随机题目",
			nowait = false,
			remap = false,
		},
		{
			"<leader>ld",
			"<cmd>Leet daily<CR>",
			desc = "打开今日题目",
			nowait = false,
			remap = false,
		},
		{
			"<leader>lt",
			"<cmd>Leet test<CR>",
			desc = "运行测试用例",
			nowait = false,
			remap = false,
		},
		{
			"<leader>ls",
			"<cmd>Leet submit<CR>",
			desc = "提交解决方案",
			nowait = false,
			remap = false,
		},
		{
			"<leader>li",
			"<cmd>Leet info<CR>",
			desc = "显示题目信息",
			nowait = false,
			remap = false,
		},
		{
			"<leader>lc",
			"<cmd>Leet console<CR>",
			desc = "打开控制台",
			nowait = false,
			remap = false,
		},
		{
			"<leader>ln",
			"<cmd>Leet tabs<CR>",
			desc = "管理标签页",
			nowait = false,
			remap = false,
		},
		{
			"<leader>ly",
			"<cmd>Leet yank<CR>",
			desc = "复制题目链接",
			nowait = false,
			remap = false,
		},
		{
			"<leader>lo",
			"<cmd>Leet open<CR>",
			desc = "在浏览器中打开",
			nowait = false,
			remap = false,
		},
		{
			"<leader>lx",
			"<cmd>Leet reset<CR>",
			desc = "重置当前题目",
			nowait = false,
			remap = false,
		},
		{
			"<leader>lg",
			"<cmd>Leet lang<CR>",
			desc = "切换编程语言",
			nowait = false,
			remap = false,
		},
		-- 认证管理子组
		{ "<leader>la", group = "认证管理", nowait = false, remap = false },
		{
			"<leader>lau",
			"<cmd>Leet cookie update<CR>",
			desc = "更新 Cookie",
			nowait = false,
			remap = false,
		},
		{
			"<leader>lad",
			"<cmd>Leet cookie delete<CR>",
			desc = "删除 Cookie",
			nowait = false,
			remap = false,
		},
	}
	
	require("which-key").add(keymap)
end

return M