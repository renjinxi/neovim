-- ================================
-- Neogit 现代化Git界面配置 (2025年版本)
-- ================================

local neogit = require("neogit")

neogit.setup({
	-- 使用telescope作为选择器
	use_telescope = true,
	
	-- Git配置
	git_services = {
		["github.com"] = "https://github.com/${owner}/${repository}/compare/${branch_name}?expand=1",
		["bitbucket.org"] = "https://bitbucket.org/${owner}/${repository}/pull-requests/new?source=${branch_name}&t=1",
		["gitlab.com"] = "https://gitlab.com/${owner}/${repository}/merge_requests/new?merge_request[source_branch]=${branch_name}",
	},
	
	-- 界面配置
	disable_hint = false,        -- 显示操作提示
	disable_context_highlighting = false,  -- 启用上下文高亮
	disable_signs = false,       -- 显示Git符号
	
	-- 弹出窗口配置
	popup = {
		kind = "split",           -- "split", "split_above", "floating"
	},
	
	-- Console输出
	console_timeout = 2000,      -- Git命令超时时间 (毫秒)
	auto_refresh = true,         -- 自动刷新状态
	
	-- 状态配置
	status = {
		recent_commit_count = 10,  -- 显示最近提交数量
	},
	
	-- 集成配置
	integrations = {
		-- 与telescope集成
		telescope = true,
		-- 与diffview集成
		diffview = true,
	},
	
	-- 简化的映射配置 (只保留基本的，避免API兼容性问题)
	mappings = {
		-- 在neogit状态页面的快捷键
		status = {
			["q"] = "Close",
			["1"] = "Depth1",
			["2"] = "Depth2", 
			["3"] = "Depth3",
			["4"] = "Depth4",
			["<tab>"] = "Toggle",
			["x"] = "Discard",
			["s"] = "Stage",
			["S"] = "StageUnstaged",
			["<c-s>"] = "StageAll",
			["u"] = "Unstage",
			["U"] = "UnstageStaged",
			["R"] = "RefreshBuffer",
			["o"] = "GoToFile",
			["<cr>"] = "GoToFile",
			["<c-v>"] = "VSplitOpen",
			["<c-x>"] = "SplitOpen",
			["<c-t>"] = "TabOpen",
		},
	},
}) 