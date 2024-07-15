local keymap = {
	{ "<leader>c", group = "QuickWindow", nowait = false, remap = false },
	{ "<leader>cl", "<cmd>cclose<cr>", desc = "Close", nowait = false, remap = false },
	{ "<leader>cn", "<cmd>cnext<cr>", desc = "Next item", nowait = false, remap = false },
	{ "<leader>co", "<cmd>copen<cr>", desc = "Open", nowait = false, remap = false },
	{ "<leader>cp", "<cmd>cprevious<cr>", desc = "Previous item", nowait = false, remap = false },
}
require("which-key").add(keymap)
