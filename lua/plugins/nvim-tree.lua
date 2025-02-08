vim.g.loaded = 1
vim.g.loaded_netrwPlugin = 1

require("nvim-tree").setup({
	update_focused_file = {
		enable = true,
		update_root = {
			enable = true,
			ignore_list = {},
		},
		exclude = false,
	},
})
require("lsp-file-operations").setup()
