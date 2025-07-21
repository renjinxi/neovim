local M = {}

function M.setup()
	-- 加载工具相关的子模块
	require("plugins.keymaps.tools.telescope").setup()
	require("plugins.keymaps.tools.fzf").setup()
	require("plugins.keymaps.tools.nvim_tree").setup()
	require("plugins.keymaps.tools.bqf").setup()
	require("plugins.keymaps.tools.claude-code").setup()
	require("plugins.keymaps.tools.leetcode").setup()
end

return M
