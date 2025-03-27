local M = {}

function M.setup()
    local options = {
        -- 编辑器显示
        number = true,                -- 显示行号
        relativenumber = false,       -- 相对行号
        cursorline = true,           -- 高亮当前行
        signcolumn = "auto",         -- 显示图标列
        cmdheight = 1,               -- 命令行高度
        showtabline = 2,             -- 总是显示标签页
        laststatus = 3,              -- 全局状态栏
        
        -- 搜索设置
        hlsearch = false,            -- 不高亮搜索结果
        ignorecase = true,           -- 搜索忽略大小写
        smartcase = true,            -- 智能大小写
        
        -- 缩进设置
        tabstop = 4,                 -- Tab宽度
        softtabstop = 4,             -- 软制表符宽度
        shiftwidth = 4,              -- 缩进宽度
        expandtab = true,            -- 使用空格代替制表符
        autoindent = true,           -- 自动缩进
        smartindent = true,          -- 智能缩进
        
        -- 文件设置
        fileformat = "unix",         -- 使用 unix 换行符
        fileencoding = "utf-8",      -- 文件编码
        
        -- 编辑体验
        mouse = "a",                 -- 启用鼠标
        splitright = true,           -- 垂直分割时新窗口在右边
        splitbelow = true,           -- 水平分割时新窗口在下边
        wrap = false,                -- 不自动换行
        scrolloff = 8,               -- 光标距离顶部/底部保持的行数
        sidescrolloff = 8,           -- 光标距离左/右保持的列数
        
        -- 性能相关
        updatetime = 300,            -- 更新时间
        timeoutlen = 500,            -- 键盘序列超时时间
        
        -- 其他设置
        termguicolors = true,        -- 启用真彩色支持
        clipboard = "unnamedplus",   -- 使用系统剪贴板
        completeopt = "menuone,noselect", -- 补全设置
        conceallevel = 0,            -- 显示隐藏字符
        showmode = false,            -- 不显示模式（由状态栏显示）
        swapfile = false,            -- 不创建交换文件
        writebackup = false,         -- 不创建备份文件
        undofile = true,             -- 启用持久撤销
        
        -- 折叠设置
        foldcolumn = "0",           -- 折叠列宽度
        foldlevel = 99,             -- 默认不折叠
        foldlevelstart = -1,        -- 打开文件时不自动折叠
        foldenable = true,          -- 启用折叠
        fillchars = "eob: ,fold: ,foldopen:,foldsep: ,foldclose:",  -- 设置填充字符
    }

    -- 应用选项
    for k, v in pairs(options) do
        vim.opt[k] = v
    end

    -- 设置 leader 键
    vim.g.mapleader = " "
    vim.g.maplocalleader = " "

    -- 加载用户自定义设置
    local ok, settings = pcall(require, "config.settings")
    if ok then
        -- Python 路径
        if settings.python3_host_prog then
            vim.g.python3_host_prog = settings.python3_host_prog
        end
        
        -- 其他自定义设置
        if settings.options then
            for k, v in pairs(settings.options) do
                vim.opt[k] = v
            end
        end
    end
end

return M 