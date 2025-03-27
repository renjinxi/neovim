local project = require("project_nvim")

project.setup({
    -- 检测这些文件/文件夹来确定项目根目录
    patterns = {
        ".git", -- Git 仓库
        "pyproject.toml", -- Python 项目
        "package.json", -- Node.js 项目
        "Cargo.toml", -- Rust 项目
        "go.mod", -- Go 项目
        "Makefile", -- Make 项目
        ".project_root" -- 自定义标记文件
    },
    -- 在切换项目时显示最近的文件
    detection_methods = { "pattern", "lsp" },
    -- 自动切换到项目目录
    scope_chdir = 'global',
    -- 在 telescope 中显示隐藏文件
    show_hidden = true,
    -- 静默模式
    silent_chdir = false,
    -- 排除某些目录
    ignore_lsp = {},
    -- 数据存储路径
    datapath = vim.fn.stdpath("data"),
}) 