local M = {}

function M.setup()
	-- 加载编辑器相关的子模块
	require("core.keymaps.editor.window").setup()
	require("core.keymaps.editor.terminal").setup()
	require("core.keymaps.editor.some_thing").setup()
end

return M
