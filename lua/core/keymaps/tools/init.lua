local M = {}

function M.setup()
	-- 加载工具相关的子模块
	require("core.keymaps.tools.telescope").setup()
	require("core.keymaps.tools.fzf").setup()
	require("core.keymaps.tools.nvim_tree").setup()
	require("core.keymaps.tools.bqf").setup()
end

return M
