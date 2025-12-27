-- Core configuration entry point
local M = {}

function M.setup()
	-- 最先加载 keymap 统计，这样可以 hook 后续所有 keymap 定义
	require("core.keymap-stats").setup()
	-- 加载基础选项
	require("core.options").setup()
	require("core.autocmds").setup()
	-- 加载用户自定义模块
	require("user.worklog").setup()
end

return M
