local M = {}

function M.setup()
	-- 加载项目管理相关的子模块
	require("plugins.keymaps.project.project").setup()
	require("plugins.keymaps.project.test").setup()
	require("plugins.keymaps.project.overseer").setup()
	require("plugins.keymaps.project.rest").setup()
	require("plugins.keymaps.project.ufo").setup()
end

return M
