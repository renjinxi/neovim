local opts = { noremap = true, silent = true }
local term_opts = { silent = true }
local keymap = vim.api.nvim_set_keymap
local open_command = 'xdg-open'
if vim.fn.has('mac') == 1 then
    open_command = 'open'
end
local function url_repo()
    local cursorword = vim.fn.expand('<cfile>')
    if string.find(cursorword, '^[a-zA-Z0-9-_.]*/[a-zA-Z0-9-_.]*$') then
        cursorword = 'https://github.com/' .. cursorword
    end
    return cursorword or ''
end

local function open_url()
    vim.fn.jobstart({ open_command, url_repo() }, { detach = true })
end

keymap('n', 'gx', open_url,  { silent = true })
-- Remap space as leader key
keymap("n", "<space>", "", opts)
keymap("t", "<Esc>", "<C-\\><C-n>", term_opts)

require("user.config.keymap.some_thing")
require("user.config.keymap.telescope")
require("user.config.keymap.window")
require("user.config.keymap.ufo")
require("user.config.keymap.lazygit")
require("user.config.keymap.lsp")
require("user.config.keymap.test")
require("user.config.keymap.dap")
require("user.config.keymap.goto_preview")
require("user.config.keymap.bqf")
require("user.config.keymap.nvim_tree")
require("user.config.keymap.terminal")

