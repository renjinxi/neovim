vim.g.loaded = 1
vim.g.loaded_netrwPlugin = 1

require("nvim-tree").setup({
	update_focused_file = {
		enable = true,
		update_root = false,
		ignore_list = {},
	},
	sync_root_with_cwd = false,
	respect_buf_cwd = true,
})
require("lsp-file-operations").setup()

