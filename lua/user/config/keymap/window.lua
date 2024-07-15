local keymap = {
	{ "<leader>w", group = "Window", nowait = false, remap = false },
	{ "<leader>wH", "<C-w>H", desc = "Window Move To Left", nowait = false, remap = false },
	{ "<leader>wJ", "<C-w>J", desc = "Window Move To Blow", nowait = false, remap = false },
	{ "<leader>wK", "<C-w>K", desc = "Window Move To Up", nowait = false, remap = false },
	{ "<leader>wL", "<C-w>L", desc = "Window Move To Right", nowait = false, remap = false },
	{ "<leader>wT", "<C-w>T", desc = "Window Move To New Tab", nowait = false, remap = false },
	{ "<leader>wh", "<C-w>h", desc = "Move To Left", nowait = false, remap = false },
	{ "<leader>wi", "<C-w>]<C-w>L", desc = "VSplit And Jump", nowait = false, remap = false },
	{ "<leader>wj", "<C-w>j", desc = "Move To Blow", nowait = false, remap = false },
	{ "<leader>wk", "<C-w>k", desc = "Move To Up", nowait = false, remap = false },
	{ "<leader>wl", "<C-w>l", desc = "Move To Right", nowait = false, remap = false },
	{ "<leader>wm", ":tabmove<cr>", desc = "Move Current Tab To Last", nowait = false, remap = false },
	{ "<leader>wt", "<C-w>]<C-w>T", desc = "Split And Jump", nowait = false, remap = false },
	{ "<leader>wu", "<C-w>]", desc = "Split And Jump", nowait = false, remap = false },
}
require("which-key").add(keymap)
for i = 1, 9 do
	local key = string.format("<leader>w%d", i)
	local cmd = string.format("<cmd>%dwincmd w<cr>", i)
	local desc = { desc = string.format("open window%d", i) }
	vim.keymap.set("n", key, cmd, desc)

	key = string.format("<leader>wc%d", i)
	cmd = string.format("<cmd>%dwincmd q<cr>", i)
	desc = { desc = string.format("close window%d", i) }
	vim.keymap.set("n", key, cmd, desc)
end
