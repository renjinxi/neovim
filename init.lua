require("before")
-- 基础配置
require("core.options").setup()
require("core.autocmds").setup()

-- 插件配置
require("config.lazy")

-- 后期配置
if vim.g.vscode then
    -- VSCode 特定配置
    require("core.keymaps").setup()
else
    -- 普通 Neovim 配置
    require("core.keymaps").setup()
    require("config.theme")
    require("lsp")
end

-- 最终配置
require("after")