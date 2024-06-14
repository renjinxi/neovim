local keymap = {
	x = {
		name = "Trouble",
		j = { "<cmd>Trouble loclist toggle<cr>", "Location List (Trouble)" },
		l = {
			"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
			"LSP Definitions / references / ... (Trouble)",
		},
		m = { "<cmd>Trouble qflist toggle<cr>", "Quickfix List (Trouble)" },
		s = { "<cmd>Trouble symbols toggle focus=false<cr>", "Symbols (Trouble)" },
		u = { "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", "Buffer Diagnostics (Trouble)" },
		x = { "<cmd>Trouble diagnostics toggle<cr>", "Diagnostics (Trouble)" },
	},
}

require("which-key").register(keymap, {
	mode = "n",
	prefix = "<leader>",
	buffer = nil,
	silent = true,
	noremap = true,
	nowait = false,
})
