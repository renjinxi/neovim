if vim.g.neovide then
    vim.o.guifont = 'Hack Nerd Font:h20'
    vim.g.neovide_fullscreen = true
    vim.keymap.set('n', '<D-s>', ':w<CR>')  -- Save
    vim.keymap.set('v', '<D-c>', '"+y')     -- Copy
    vim.keymap.set('n', '<D-v>', '"+P')     -- Paste normal mode
    vim.keymap.set('v', '<D-v>', '"+P')     -- Paste visual mode
    vim.keymap.set('c', '<D-v>', '<C-R>+')  -- Paste command mode
    vim.keymap.set('i', '<D-v>', '<ESC>l"+Pli') -- Paste insert mode
    -- Allow clipboard copy paste in neovim
    vim.api.nvim_set_keymap('', '<D-v>', '+p<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('!', '<D-v>', '<C-R>+', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('t', '<D-v>', '<C-R>+', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('v', '<D-v>', '<C-R>+', { noremap = true, silent = true })

    vim.g.neovide_floating_shadow = false

    -- send alt+whatever to neovim
    vim.g.neovide_input_macos_alt_is_meta = true
end
