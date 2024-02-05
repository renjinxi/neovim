local status_ok, tree = pcall(require, "nvim-tree")
if not status_ok then
    return
end

vim.g.loaded = 1
vim.g.loaded_netrwPlugin = 1

tree.setup({
    update_focused_file = {
        enable = true,
        update_root = true,
        ignore_list = {},
    },
})

local status_ok, which_key = pcall(require, "which-key")

if not status_ok then
    return
end

local keymap = {
    t = {
        name = "Nvim Tree",
        n = { "<cmd>NvimTreeOpen<cr>", "Open" },
        u = { "<cmd>NvimTreeToggle<cr>", "Toggle" },
        o = { "<cmd>NvimTreeFocus<cr>", "Focus" },
    },
}

local opts = {
    mode = "n",
    prefix = "<leader>",
    buffer = nil,
    silent = true,
    noremap = true,
    nowait = false,
}

which_key.register(keymap, opts)
