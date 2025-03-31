local M = {}

function M.setup()
	-- 加载调试相关的子模块
	require("plugins.keymaps.debug.dap").setup()
	require("plugins.keymaps.debug.trouble").setup()
end

return M
