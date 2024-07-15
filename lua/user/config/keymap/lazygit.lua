local keymap = {
	{ "<leader>s", group = "Lazygit", nowait = false, remap = false },
	{ "<leader>sl", ":LazyGit<cr>", desc = "Lazygit", nowait = false, remap = false },
}
require("which-key").add(keymap)
