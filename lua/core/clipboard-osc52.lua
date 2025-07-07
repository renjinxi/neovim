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
end

-- 复制整个缓冲区内容
function M.copy_buffer()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local text = table.concat(lines, '\n')
    M.copy_to_clipboard(text)
end



-- 创建用户命令
function M.setup_commands()
    vim.api.nvim_create_user_command('OSC52CopyBuffer', M.copy_buffer, {
        desc = '通过OSC52复制整个缓冲区到本地剪贴板'
    })
end

-- 自动复制到本地剪贴板的功能
function M.setup_auto_copy()
    -- 创建自动命令组
    local group = vim.api.nvim_create_augroup('OSC52AutoCopy', { clear = true })
    
    -- 监听TextYankPost事件，当复制文本时自动发送到本地剪贴板
    vim.api.nvim_create_autocmd('TextYankPost', {
        group = group,
        callback = function()
            -- 获取复制的内容
            local content = vim.v.event.regcontents
            if content and #content > 0 then
                local text = table.concat(content, '\n')
                M.copy_to_clipboard(text)
            end
        end,
    })
end

-- 设置快捷键
function M.setup_keymaps()
    -- 复制整个缓冲区到本地剪贴板
    vim.keymap.set('n', '<leader>ya', M.copy_buffer, { 
        desc = '复制整个文件到本地剪贴板(OSC52)' 
    })
end

return M 