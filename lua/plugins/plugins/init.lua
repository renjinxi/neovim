if vim.g.vscode then
	return require("plugins.plugins.vscode")
else
	return require("plugins.plugins.nvim") -- 非 VSCode 环境
end
