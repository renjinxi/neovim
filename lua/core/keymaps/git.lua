local M = {}

function M.setup()
    local opts = { noremap = true, silent = true }
    local keymap = vim.keymap.set
    
    -- Git 操作
    -- 状态
    keymap("n", "<leader>gs", ":Git<CR>", opts)
    
    -- 提交
    keymap("n", "<leader>gc", ":Git commit<CR>", opts)
    
    -- 推送
    keymap("n", "<leader>gp", ":Git push<CR>", opts)
    
    -- 拉取
    keymap("n", "<leader>gl", ":Git pull<CR>", opts)
    
    -- 差异对比
    keymap("n", "<leader>gd", ":Gdiff<CR>", opts)
    
    -- 合并冲突
    keymap("n", "<leader>gh", ":diffget //2<CR>", opts)  -- 选择左侧版本
    keymap("n", "<leader>gl", ":diffget //3<CR>", opts)  -- 选择右侧版本
    
    -- 分支操作
    keymap("n", "<leader>gb", ":Git branch<CR>", opts)   -- 查看分支
    keymap("n", "<leader>gco", ":Git checkout ", opts)   -- 切换分支
    
    -- 日志查看
    keymap("n", "<leader>glo", ":Git log<CR>", opts)
    
    -- 暂存操作
    keymap("n", "<leader>ga", ":Git add .<CR>", opts)    -- 暂存所有
    keymap("n", "<leader>gr", ":Git reset<CR>", opts)    -- 取消暂存
    
    -- 撤销修改
    keymap("n", "<leader>gu", ":Git restore .", opts)    -- 撤销所有未暂存的修改
end

return M 