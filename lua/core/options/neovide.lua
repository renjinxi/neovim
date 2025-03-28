local M = {}

function M.setup()
    -- 字体设置
    vim.o.guifont = 'Hack Nerd Font:h20'
    
    -- Neovide 特定设置
    vim.g.neovide_fullscreen = true
    vim.g.neovide_floating_shadow = false
    vim.g.neovide_input_macos_option_key_is_meta = "both"

    -- macOS 特定快捷键
    local keymap = vim.keymap.set
    keymap('n', '<D-s>', ':w<CR>')      -- Save
    keymap('v', '<D-c>', '"+y')         -- Copy
    keymap('n', '<D-v>', '"+P')         -- Paste normal mode
    keymap('v', '<D-v>', '"+P')         -- Paste visual mode
    keymap('c', '<D-v>', '<C-R>+')      -- Paste command mode
    keymap('i', '<D-v>', '<ESC>l"+Pli') -- Paste insert mode

    -- 剪贴板集成
    local function set_keymap(mode, lhs, rhs, opts)
        vim.api.nvim_set_keymap(mode, lhs, rhs, opts or { noremap = true, silent = true })
    end

    set_keymap('', '<D-v>', '+p<CR>')
    set_keymap('!', '<D-v>', '<C-R>+')
    set_keymap('t', '<D-v>', '<C-o>p')
    set_keymap('v', '<D-v>', '<C-R>+')
end

return M 