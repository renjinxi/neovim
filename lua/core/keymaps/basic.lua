local M = {}

function M.setup()
    local opts = { noremap = true, silent = true }
    local keymap = vim.keymap.set
    
    -- Leader 键
    keymap("", "<Space>", "<Nop>", opts)
    vim.g.mapleader = " "
    vim.g.maplocalleader = " "
    
    -- 正常模式 --
    -- 窗口导航
    keymap("n", "<C-h>", "<C-w>h", opts)
    keymap("n", "<C-j>", "<C-w>j", opts)
    keymap("n", "<C-k>", "<C-w>k", opts)
    keymap("n", "<C-l>", "<C-w>l", opts)
    
    -- 调整窗口大小
    keymap("n", "<C-Up>", ":resize -2<CR>", opts)
    keymap("n", "<C-Down>", ":resize +2<CR>", opts)
    keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
    keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)
    
    -- 缓冲区导航
    keymap("n", "<S-l>", ":bnext<CR>", opts)
    keymap("n", "<S-h>", ":bprevious<CR>", opts)
    
    -- 移动文本
    keymap("n", "<A-j>", ":m .+1<CR>==", opts)
    keymap("n", "<A-k>", ":m .-2<CR>==", opts)
    
    -- 插入模式 --
    -- 快速退出插入模式
    keymap("i", "jk", "<ESC>", opts)
    keymap("i", "kj", "<ESC>", opts)
    
    -- 可视模式 --
    -- 保持缩进
    keymap("v", "<", "<gv", opts)
    keymap("v", ">", ">gv", opts)
    
    -- 移动文本
    keymap("v", "<A-j>", ":m '>+1<CR>gv=gv", opts)
    keymap("v", "<A-k>", ":m '<-2<CR>gv=gv", opts)
    
    -- 保持粘贴内容
    keymap("v", "p", '"_dP', opts)
    
    -- 可视块模式 --
    -- 移动文本
    keymap("x", "J", ":m '>+1<CR>gv=gv", opts)
    keymap("x", "K", ":m '<-2<CR>gv=gv", opts)
    keymap("x", "<A-j>", ":m '>+1<CR>gv=gv", opts)
    keymap("x", "<A-k>", ":m '<-2<CR>gv=gv", opts)
    
    -- 终端模式 --
    -- 终端导航
    keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", opts)
    keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", opts)
    keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", opts)
    keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", opts)
    keymap("t", "<Esc>", "<C-\\><C-n>", opts)
end

return M 