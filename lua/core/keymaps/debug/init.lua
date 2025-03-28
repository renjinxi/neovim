local M = {}

function M.setup()
	-- 加载调试相关的子模块
	require("core.keymaps.debug.dap").setup()
	require("core.keymaps.debug.trouble").setup()
end

return M
