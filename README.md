~/.config/nvim/
├── init.lua                  # 主配置入口文件
├── lua/                     # Lua 模块目录
│   ├── core/               # 核心配置
│   │   ├── options.lua     # 基础 vim 选项设置
│   │   ├── keymaps.lua    # 快捷键映射
│   │   ├── autocmds.lua   # 自动命令
│   │   └── colorscheme.lua # 配色方案设置
│   ├── plugins/            # 插件配置目录
│   │   ├── init.lua       # 插件管理器设置(如 lazy.nvim)
│   │   ├── lsp/          # LSP 相关配置
│   │   │   ├── init.lua
│   │   │   └── config/   # 各语言 LSP 配置
│   │   ├── completion/   # 自动完成相关配置
│   │   ├── treesitter/   # 语法高亮配置
│   │   └── ui/          # UI 相关插件配置
│   └── utils/            # 工具函数
├── snippets/              # 代码片段
├── ftplugin/             # 文件类型特定设置
└── after/                # 后期加载的配置
    └── plugin/           # 插件后期配置