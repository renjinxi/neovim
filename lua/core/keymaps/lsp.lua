local M = {}

function M.setup()
    local opts = { noremap = true, silent = true }
    local keymap = vim.keymap.set
    
    -- LSP 相关快捷键
    -- 跳转到定义
    keymap("n", "gd", vim.lsp.buf.definition, opts)
    
    -- 显示悬浮文档
    keymap("n", "K", vim.lsp.buf.hover, opts)
    
    -- 跳转到实现
    keymap("n", "gi", vim.lsp.buf.implementation, opts)
    
    -- 显示签名帮助
    keymap("n", "<C-k>", vim.lsp.buf.signature_help, opts)
    
    -- 重命名
    keymap("n", "<leader>rn", vim.lsp.buf.rename, opts)
    
    -- 代码操作
    keymap("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    
    -- 跳转到引用
    keymap("n", "gr", vim.lsp.buf.references, opts)
    
    -- 显示诊断
    keymap("n", "<leader>e", vim.diagnostic.open_float, opts)
    keymap("n", "[d", vim.diagnostic.goto_prev, opts)
    keymap("n", "]d", vim.diagnostic.goto_next, opts)
    keymap("n", "<leader>q", vim.diagnostic.setloclist, opts)
    
    -- 工作区相关
    keymap("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts)
    keymap("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts)
    keymap("n", "<leader>wl", function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    
    -- 类型定义
    keymap("n", "<leader>D", vim.lsp.buf.type_definition, opts)
end

return M 