local M = {}

function M.setup()
	-- 加载 LSP 相关的子模块
	require("plugins.keymaps.lsp.lsp").setup()
	require("plugins.keymaps.lsp.goto_preview").setup()
end

return M
