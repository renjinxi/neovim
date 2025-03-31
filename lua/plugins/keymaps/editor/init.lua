local M = {}

function M.setup()
	-- 加载编辑器相关的子模块
	require("plugins.keymaps.editor.window").setup()
	require("plugins.keymaps.editor.terminal").setup()
	require("plugins.keymaps.editor.some_thing").setup()
end

return M
