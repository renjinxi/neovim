if vim.g.vscode then
	return require("plugins.plugins.vscode")
else
	return require("plugins.plugins.nvim")
end 