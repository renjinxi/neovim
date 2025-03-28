local M = {}

function M.setup()
	-- 加载 LSP 相关的子模块
	require("core.keymaps.lsp.lsp").setup()
	require("core.keymaps.lsp.goto_preview").setup()
end

return M
