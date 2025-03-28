local M = {}

function M.reload_config()
    -- 清除已加载的模块缓存
    for name, _ in pairs(package.loaded) do
        if name:match('^config%.') or name:match('^plugins%.') or name:match('^lsp%.') then
            package.loaded[name] = nil
        end
    end

    -- 重新加载主要配置模块
    require('config.options')
    require('config.auto_commands')
    require('config.keymap')
    require('config.theme')
    require('lua.plugins.lsp.init')

    -- 重新加载插件配置
    require('lazy').sync()

    -- 通知用户
    vim.notify('配置已重新加载', vim.log.levels.INFO)
end

return M 