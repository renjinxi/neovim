-- 最小配置，用于查看kitty scrollback
-- 设置基本选项
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.wrap = false
vim.opt.termguicolors = true

-- 设置 leader 键
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 基本按键映射
vim.keymap.set("n", "q", "<cmd>qa!<cr>", { desc = "Quit" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search" })