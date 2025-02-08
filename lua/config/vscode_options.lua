local options = {
    -- 缩进设置
    tabstop = 4,
    softtabstop = 4,
    shiftwidth = 4,
    expandtab = true,
    autoindent = true,
    -- relativenumber = true,

    -- 文件格式
    fileformat = "unix",
    swapfile = false,

    -- 搜索
    hlsearch = false,
}

-- 应用配置
for k, v in pairs(options) do
    vim.opt[k] = v
end

-- 剪贴板设置
vim.cmd("set clipboard=unnamedplus")

-- 设置leader键
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Python 格式化设置
vim.g.vscode_settings = {
    ["editor.defaultFormatter"] = "charliermarsh.ruff",
    ["editor.formatOnSave"] = true,
    ["[python]"] = {
        ["editor.defaultFormatter"] = "charliermarsh.ruff",
        ["editor.formatOnSave"] = true,
        ["editor.codeActionsOnSave"] = {
            ["source.organizeImports"] = true
        }
    }
}
