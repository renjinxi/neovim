local M = {}

function M.setup()
    local opts = { noremap = true, silent = true }
    local keymap = vim.keymap.set
    
    -- 编辑器功能
    -- 保存和退出
    keymap("n", "<leader>w", ":w<CR>", opts)
    keymap("n", "<leader>q", ":q<CR>", opts)
    keymap("n", "<leader>Q", ":qa!<CR>", opts)
    
    -- 搜索
    keymap("n", "<leader>h", ":nohlsearch<CR>", opts)
    keymap("n", "n", "nzzzv", opts)
    keymap("n", "N", "Nzzzv", opts)
    
    -- 分屏
    keymap("n", "<leader>sv", ":vsplit<CR>", opts)
    keymap("n", "<leader>sh", ":split<CR>", opts)
    
    -- 关闭缓冲区
    keymap("n", "<leader>c", ":bdelete<CR>", opts)
    
    -- 快速移动
    keymap("n", "<C-d>", "<C-d>zz", opts)
    keymap("n", "<C-u>", "<C-u>zz", opts)
    
    -- 快速替换
    keymap("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], opts)
    
    -- 快速复制到系统剪贴板
    keymap("n", "<leader>y", '"+y', opts)
    keymap("v", "<leader>y", '"+y', opts)
    keymap("n", "<leader>Y", '"+Y', opts)
    
    -- 快速删除到虚空寄存器
    keymap("n", "<leader>d", '"_d', opts)
    keymap("v", "<leader>d", '"_d', opts)
    
    -- 格式化
    keymap("n", "<leader>f", vim.lsp.buf.format, opts)
end

return M 