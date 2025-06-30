local M = {}

-- OSC52剪贴板功能实现
function M.copy_to_clipboard(text)
    if not text or text == "" then
        return
    end
    
    -- 移除末尾的换行符，避免多余的空行
    text = text:gsub('\n$', '')
    
    -- 使用OSC52转义序列将内容发送到本地剪贴板
    -- OSC52格式: \033]52;c;base64_encoded_text\007
    local osc52 = string.format('\027]52;c;%s\007', vim.base64.encode(text))
    
    -- 输出到stdout，让终端处理剪贴板
    io.stdout:write(osc52)
    io.stdout:flush()
    
    print(string.format("✓ 已通过OSC52复制 %d 个字符到本地剪贴板", #text))
end

-- 获取当前选中内容并复制到剪贴板
function M.copy_selection()
    local mode = vim.fn.mode()
    local text = ""
    
    if mode == 'v' or mode == 'V' or mode == '\22' then
        -- 可视模式：获取选中的文本
        vim.cmd('normal! "zy')
        text = vim.fn.getreg('z')
    else
        -- 普通模式：获取当前行
        text = vim.fn.getline('.')
    end
    
    if text and text ~= "" then
        M.copy_to_clipboard(text)
    end
end

-- 复制整个缓冲区内容
function M.copy_buffer()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local text = table.concat(lines, '\n')
    M.copy_to_clipboard(text)
end

-- 设置OSC52剪贴板provider
function M.setup_osc52_clipboard()
    vim.g.clipboard = {
        name = 'OSC52',
        copy = {
            ['+'] = function(lines, regtype)
                local text = table.concat(lines, '\n')
                M.copy_to_clipboard(text)
            end,
            ['*'] = function(lines, regtype)
                local text = table.concat(lines, '\n')
                M.copy_to_clipboard(text)
            end,
        },
        paste = {
            ['+'] = function()
                -- OSC52不支持粘贴，使用终端的粘贴功能
                vim.notify("请使用终端的粘贴快捷键 (Cmd+V 或 Ctrl+Shift+V)", vim.log.levels.INFO)
                return {''}
            end,
            ['*'] = function()
                vim.notify("请使用终端的粘贴快捷键 (Cmd+V 或 Ctrl+Shift+V)", vim.log.levels.INFO)
                return {''}
            end,
        },
    }
end

-- 创建用户命令
function M.setup_commands()
    vim.api.nvim_create_user_command('OSC52CopySelection', M.copy_selection, {
        desc = '通过OSC52复制选中内容到本地剪贴板'
    })
    
    vim.api.nvim_create_user_command('OSC52CopyBuffer', M.copy_buffer, {
        desc = '通过OSC52复制整个缓冲区到本地剪贴板'
    })
end

-- 设置快捷键
function M.setup_keymaps()
    -- 在可视模式下复制选中内容
    vim.keymap.set('v', '<leader>cy', M.copy_selection, { 
        desc = 'OSC52复制选中内容到本地剪贴板' 
    })
    
    -- 在普通模式下复制当前行
    vim.keymap.set('n', '<leader>cyy', M.copy_selection, { 
        desc = 'OSC52复制当前行到本地剪贴板' 
    })
    
    -- 复制整个缓冲区
    vim.keymap.set('n', '<leader>cya', M.copy_buffer, { 
        desc = 'OSC52复制整个文件到本地剪贴板' 
    })
end

return M 