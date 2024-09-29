local M = {}

M.settings = {
	Lua = {
		diagnostics = {
			globals = { "vim", "bit" },
		},
		workspace = {
			-- Add Neovim runtime path
			library = vim.api.nvim_get_runtime_file("", true),
			-- Make the language server aware of Neovim's built-in Lua
			checkThirdParty = false,
		},
		telemetry = {
			enable = false,
		},
	},
}

return M
