local api = vim.api
local opt = vim.opt

local indent_group = api.nvim_create_augroup("indent_group", { clear = true })
local relative_group = api.nvim_create_augroup("relative_group", { clear = true })

vim.api.nvim_create_augroup('NoHlSearch', { clear = true })
vim.api.nvim_create_autocmd('BufEnter', {
    group = 'NoHlSearch',
    callback = function()
        vim.opt.hlsearch = false
    end,
})

vim.api.nvim_create_augroup("NoSignColumnBg", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", {
    group = "NoSignColumnBg",
    callback = function()
        vim.cmd("highlight SignColumn guibg=#ffffff")
    end
})


local function set_indent()
    local default_value = 4
    local indent_table = {
        python = 4,
        markdown = 4,
        --toml = 2,
        --c = 4,
    }

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


api.nvim_create_autocmd({ "WinEnter", "BufRead", "BufEnter", "FocusGained" }, {
    pattern = "*",
    group = relative_group,
    desc = "set relativenumber for file",
    callback = set_relativenumber,
})

api.nvim_create_autocmd({ "WinLeave", "BufLeave", "FocusLost" }, {
    --api.nvim_create_autocmd({ "FocusLost" }, {
    pattern = "*",
    group = relative_group,
    desc = "set norelativenumber for file",
    callback = set_norelativenumber,
})

local lsp = vim.lsp
-- 创建一个自动命令组用于管理事件
local lsp_group = api.nvim_create_augroup("lsp_group", { clear = true })

-- 创建一个回调函数，用于关闭所有的 LSP
local function stop_all_lsp()
    -- 停止所有的 LSP 客户端
    lsp.stop_client(lsp.get_active_clients())
end

-- 创建一个回调函数，用于启动 LSP
local function start_lsp()
    -- 启动 LSP 客户端
	vim.cmd("LspStart")
end

-- 创建一个自动命令，当切换到新的 tab 时触发
api.nvim_create_autocmd("TabEnter", {
    group = "lsp_group",  -- 使用前面创建的自动命令组
    callback = function()
        -- 在切换到新的 tab 时先停止所有的 LSP
        stop_all_lsp()

        -- 等待一段时间后重新启动 LSP
        vim.defer_fn(start_lsp, 1000)
    end,
})
