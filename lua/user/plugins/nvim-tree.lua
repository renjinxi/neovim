vim.g.loaded = 1
vim.g.loaded_netrwPlugin = 1

require("nvim-tree").setup({
    update_focused_file = {
        enable = true,
        update_root = true,
        ignore_list = {},
    },
})
require("lsp-file-operations").setup()

