local normal_opts = {
	mode = "n",
	prefix = "<leader>",
	buffer = nil,
	silent = true,
	noremap = true,
	nowait = false,
}

local keymap = {
	w = {
		name = "Window",
		H = { "<C-w>H", "Window Move To Left" },
		J = { "<C-w>J", "Window Move To Blow" },
		K = { "<C-w>K", "Window Move To Up" },
		L = { "<C-w>L", "Window Move To Right" },
		T = { "<C-w>T", "Window Move To New Tab" },

		h = { "<C-w>h", "Move To Left" },
		i = { "<C-w>]<C-w>L", "VSplit And Jump" },
		j = { "<C-w>j", "Move To Blow" },
		k = { "<C-w>k", "Move To Up" },
		l = { "<C-w>l", "Move To Right" },
		t = { "<C-w>]<C-w>T", "Split And Jump" },
		u = { "<C-w>]", "Split And Jump" },
		m = { ":tabmove<cr>", "Move Current Tab To Last" },
	},
}

require("which-key").register(keymap, normal_opts)
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
