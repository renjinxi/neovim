local M = {}

function M.setup()
	-- 加载基础环境变量
	require("core.env")

	if vim.g.vscode then
		-- VSCode 环境
		require("core.options.vscode").setup()
	elseif vim.g.neovide then
		-- Neovide 环境
		require("core.options.base").setup()
		require("core.options.neovide").setup()
	else
		-- 普通 Neovim 环境
		require("core.options.base").setup()
	end
end

return M
