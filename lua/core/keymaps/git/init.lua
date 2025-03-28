local M = {}

function M.setup()
	-- 加载 Git 相关的子模块
	require("core.keymaps.git.git").setup()
end

return M
