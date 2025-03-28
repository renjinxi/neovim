local M = {}

function M.setup()
	-- 加载项目管理相关的子模块
	require("core.keymaps.project.project").setup()
	require("core.keymaps.project.test").setup()
	require("core.keymaps.project.overseer").setup()
	require("core.keymaps.project.rest").setup()
	require("core.keymaps.project.ufo").setup()
end

return M
