local normal_opts = {
	mode = "n",
	prefix = "<leader>",
	buffer = nil,
	silent = true,
	noremap = true,
	nowait = false,
}

local lazygit_keymap = {
    s = {
        name = "Lazygit",
        l = { ":LazyGit<cr>", "Lazygit" },
    }
}

require("which-key").register(lazygit_keymap, normal_opts)
