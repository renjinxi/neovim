local M = {}

-- 定义全局 set_terminal_keymaps 函数
_G.set_terminal_keymaps = function()
    vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", { buffer = true })
    vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", { buffer = true })
    vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", { buffer = true })
    vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", { buffer = true })
end

function M.setup()
    -- 设置终端按键映射
    vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "term://*",
        callback = function()
            set_terminal_keymaps()
        end,
    })
end

return M 