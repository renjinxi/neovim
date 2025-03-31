local M = {}

function M.setup()
	local keymap = {
		{ "<leader>t", group = "Nvim Tree", nowait = false, remap = false },
		{ "<leader>tn", "<cmd>NvimTreeOpen<cr>", desc = "Open", nowait = false, remap = false },
		{ "<leader>to", "<cmd>NvimTreeFocus<cr>", desc = "Focus", nowait = false, remap = false },
		{ "<leader>tu", "<cmd>NvimTreeToggle<cr>", desc = "Toggle", nowait = false, remap = false },
	}
	require("which-key").add(keymap)
end

return M
