local options = {
    number = true,
    cmdheight = 1,
    --autoread = true,
    --guioptions = vim.opt.guioptions - {"r", "l", "b"},
    cursorline = true,
    mouse = "a",
    showtabline = 2,
    --foldmethod = "expr",
    --foldexpr = vim.call("nvim_treesitter#foldexpr"),
    foldcolumn = "1", -- '0' is not bad
    foldlevel = 99,   -- Using ufo provider need a large value, feel free to decrease the value
    foldlevelstart = -1,
    foldenable = true,
    fillchars = "eob: ,fold: ,foldopen:,foldsep: ,foldclose:",

    tabstop = 4,
    softtabstop = 4,
    shiftwidth = 4,

    textwidth = 79,
    expandtab = true,
    autoindent = true,
    fileformat = "unix",
    --relativenumber = true,
    splitright = true,
    --nohlsearch = true,
    --termguicolors = true,
}

for k, v in pairs(options) do
    vim.opt[k] = v
end

vim.cmd("set clipboard=unnamedplus ")
vim.cmd("set nohlsearch")
