-- Core configuration entry point
local M = {}

function M.setup()
	-- 最先加载 keymap 统计，这样可以 hook 后续所有 keymap 定义
	require("core.keymap-stats").setup()
	-- 加载基础选项
	require("core.options").setup()
	-- 初始化当前 nvim 实例的 RPC 地址和 AI 约定环境变量
	require("core.nvim_instance").setup()
	require("core.autocmds").setup()
	-- AI 任务文件监听
	require("core.task_watcher").setup()
	-- 加载用户自定义模块
	require("user.worklog").setup()
end

return M
