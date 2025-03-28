require("core.options").setup()
require("core.autocmds").setup()
require("plugins")

require("core.keymaps").setup()

if not vim.g.vscode then
	require("core.theme").setup()
	require("plugins.lsp.init")
end
