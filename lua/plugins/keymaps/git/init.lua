local M = {}

function M.setup()
	-- 加载 Git 相关的子模块
	require("plugins.keymaps.git.git").setup()
end

return M
