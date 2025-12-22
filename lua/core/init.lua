-- Core configuration entry point
local M = {}

function M.setup()
	-- 加载基础选项
	require("core.options").setup()
	require("core.autocmds").setup()
	-- 加载用户自定义模块
	require("user.worklog").setup()
end

return M
