local M = {}

function M.setup()
	local keymap = {
		{ "<leader>t", group = "File Tree", nowait = false, remap = false },
		{ "<leader>tt", "<cmd>NvimTreeToggle<cr>", desc = "Toggle", nowait = false, remap = false },
		{ "<leader>tf", "<cmd>NvimTreeFocus<cr>", desc = "Focus", nowait = false, remap = false },
		{ "<leader>tr", "<cmd>NvimTreeFindFile<cr>", desc = "Find current file", nowait = false, remap = false },
		{ "<leader>tc", "<cmd>NvimTreeClose<cr>", desc = "Close", nowait = false, remap = false },
	}
	require("which-key").add(keymap)
end

return M
