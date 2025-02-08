require("before")

if vim.g.vscode then
    -- VSCode模式下的配置
    print(1)
    require("config.vscode_options")
    require("config.lazy")
else
    -- 普通Neovim的配置
    print(2)
    require("config.neovide_config")
    require("config.options")
    require("config.lazy")
    require("config.auto_commands")
    require("config.theme")
    require("config.keymap")
    require("lsp")
end

require("after")
