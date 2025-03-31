local M = {}

function M.setup()
	local keymap = {
		{ "<leader>x", group = "Trouble", nowait = false, remap = false },
		{
			"<leader>xj",
			"<cmd>Trouble loclist toggle<cr>",
			desc = "Location List (Trouble)",
			nowait = false,
			remap = false,
		},
		{
			"<leader>xl",
			"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
			desc = "LSP Definitions / references / ... (Trouble)",
			nowait = false,
			remap = false,
		},
		{
			"<leader>xm",
			"<cmd>Trouble qflist toggle<cr>",
			desc = "Quickfix List (Trouble)",
			nowait = false,
			remap = false,
		},
		{
			"<leader>xs",
			"<cmd>Trouble symbols toggle focus=false<cr>",
			desc = "Symbols (Trouble)",
			nowait = false,
			remap = false,
		},
		{
			"<leader>xu",
			"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
			desc = "Buffer Diagnostics (Trouble)",
			nowait = false,
			remap = false,
		},
		{
			"<leader>xx",
			"<cmd>Trouble diagnostics toggle<cr>",
			desc = "Diagnostics (Trouble)",
			nowait = false,
			remap = false,
		},
	}
	require("which-key").add(keymap)
end

return M
