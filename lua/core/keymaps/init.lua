local M = {}

function M.setup()
    -- 基础快捷键
    require("core.keymaps.basic").setup()
    
    -- 编辑器功能快捷键
    require("core.keymaps.editor").setup()
    
    -- Git 相关快捷键
    require("core.keymaps.git").setup()
    
    -- LSP 相关快捷键
    require("core.keymaps.lsp").setup()
    
    -- 插件快捷键
    require("core.keymaps.plugins").setup()
    
    -- 用户自定义快捷键
    local ok, custom_keymaps = pcall(require, "config.keymaps")
    if ok and type(custom_keymaps) == "function" then
        custom_keymaps()
    end
end

return M 