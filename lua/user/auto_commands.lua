local api = vim.api
local opt = vim.opt

local indent_group = api.nvim_create_augroup("indent_group", { clear = true })
local relative_group = api.nvim_create_augroup("relative_group", { clear = true })

local function set_indent()
        local default_value = 8
        local indent_table = {
                python = 4,
                markdown = 4,
                c = 8,
        }

        opt.textwidth = 150
        opt.expandtab = true
        opt.autoindent = true
        for key, value in pairs(indent_table) do
                if vim.bo.filetype == key then
                        opt.tabstop = value
                        opt.softtabstop = value
                        opt.shiftwidth = value
                        return
                end
        end
        opt.tabstop = default_value
        opt.softtabstop = default_value
        opt.shiftwidth = default_value
end

api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {

        pattern = "*",
        group = indent_group,
        desc = "set indent for file",
        callback = set_indent,
})

-- reload buffer file when file changed on disk
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
        command = "if mode() != 'c' | checktime | endif",
        pattern = { "*" },
})

local function set_relativenumber()
        vim.opt.relativenumber = true
end

local function set_norelativenumber()
        vim.opt.relativenumber = false
end


--api.nvim_create_autocmd({ "BufEnter", "BufRead" }, {
--api.nvim_create_autocmd({ "WinEnter", "FocusGained" }, {
api.nvim_create_autocmd({ "WinEnter" }, {
        pattern = "*",
        group = relative_group,
        desc = "set relativenumber for file",
        callback = set_relativenumber,
})

--api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
api.nvim_create_autocmd({ "WinLeave" }, {
        --api.nvim_create_autocmd({ "FocusLost" }, {
        pattern = "*",
        group = relative_group,
        desc = "set norelativenumber for file",
        callback = set_norelativenumber,
})
