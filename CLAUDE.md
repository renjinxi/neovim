# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a modern, sophisticated Neovim configuration built with Lua. It supports both native Neovim environments and VSCode/Cursor integration with intelligent environment detection and conditional loading.

## Configuration Management

### Plugin Management
- Uses **Lazy.nvim** as the plugin manager with lazy loading
- Plugin lock file: `lazy-lock.json` (commit this file to freeze dependencies)
- Auto-installation disabled - plugins must be explicitly updated
- **90+ plugins** organized by functional areas

### Environment Configuration
- Environment variables stored in `.env` file (create from `.env.example`)
- Python host program configuration
- Claude API token configuration for custom commands (gc1, gc2)
- Smart environment detection for VSCode/Cursor vs native Neovim

### Plugin Updates and Management
```lua
-- Update all plugins
:Lazy update

-- Install missing plugins
:Lazy install

-- View plugin status
:Lazy

-- Restore from lockfile
:Lazy restore
```

## Architecture Overview

### Core Structure
```
lua/
├── core/                 # Base Neovim configuration
│   ├── options/         # Environment-specific vim options
│   ├── autocmds.lua    # Auto-commands (relative numbers, file reload)
│   ├── env.lua         # Environment variable management
│   └── im-switch.lua   # Input method switching
├── plugins/            # Plugin ecosystem
│   ├── plugins/        # Plugin specifications (lazy.nvim specs)
│   ├── config/         # Individual plugin configurations (35+ files)
│   ├── keymaps/        # Organized keymap modules by feature area
│   └── dap/           # Debug adapter protocol configuration
└── user/              # User-specific customizations
```

### Environment-Aware Loading
The configuration automatically detects and loads different configurations based on environment:

- **VSCode/Cursor**: Limited plugin set focused on editing
- **Native Neovim**: Full feature set with LSP, debugging, UI enhancements

Check environment: `vim.g.vscode` is set in VSCode/Cursor environments.

### Keymap Organization
**集中式管理**：所有快捷键统一在两个文件中管理：

```
keymaps/
├── all.lua        # 所有快捷键定义，按 <leader> 前缀分组
└── functions.lua  # 复杂回调函数，供 all.lua 引用
```

- `all.lua`：快捷键注册中心，使用 which-key 格式
- `functions.lua`：复杂功能的实现（终端、Git、DAP 等）
- 新增快捷键必须在 `all.lua` 中注册，不要在 config 文件中直接定义

## Language Server Protocol (LSP)

### Configuration
- Modern Neovim 0.11+ compatible using `vim.lsp.config()`
- Supports 15+ language servers via Mason
- Automatic server installation and configuration
- Per-language server customization in `lua/plugins/config/lsp.lua`

### Supported Languages
Web: html, css, typescript, javascript
Systems: C/C++ (clangd), Go (gopls), Python (pyright + ruff)
Config: JSON, YAML, Nginx, Lua

### Mason Commands
```lua
-- Update Mason registry
:MasonRegistryUpdate

-- Install/manage packages
:Mason

-- Check installed packages
:MasonLog
```

## Debugging (DAP)

Multi-language debugging support with nvim-dap:

### Supported Languages
- **Python**: debugpy
- **C/C++**: gdb/lldb
- **Go**: delve
- **JavaScript/TypeScript**: node debug

### DAP Configuration
Language-specific configs in `lua/plugins/dap/language/`
UI configuration with nvim-dap-ui for enhanced debugging experience.

## Theme and UI

### Primary Theme: Rose Pine
- High-priority loading for consistent appearance
- Custom color palette integration with statusline

### Status Bar: Heirline
Modern, highly customizable status bar with components:
- Vi mode indicator
- Git information
- LSP diagnostics
- File information
- Clock
- Buffer/tab management

## Key Plugin Categories

### Core Development
- **LSP**: nvim-lspconfig, mason, mason-lspconfig
- **Completion**: nvim-cmp + luasnip + friendly-snippets
- **Syntax**: nvim-treesitter
- **Debug**: nvim-dap + language adapters

### Navigation & Search
- **Flash**: Fast navigation within buffers
- **Telescope**: Fuzzy finder for files, buffers, grep
- **FZF**: Alternative fuzzy finder
- **nvim-tree**: File explorer

### Git Integration
- **Neogit**: Git interface
- **LazyGit**: Terminal git UI
- **gitsigns**: Git decorations
- **diffview**: Git diff visualization

### Productivity
- **Overseer**: Task runner
- **Neotest**: Testing framework
- **原生终端**: 使用 nvim API 实现的终端管理（float/horizontal/vertical/tab）
- **possession**: Session management
- **浮动终端**: 支持多个 Claude/普通终端浮动窗口，智能避让布局
- **多 Git Repo**: 支持在一个目录下管理多个 Git 仓库的变更

## Configuration Patterns

### Adding New Plugins
1. Add spec to `lua/plugins/plugins/nvim.lua` (or `vscode.lua` for VSCode-specific)
2. Create config file in `lua/plugins/config/[plugin-name].lua`
3. Add keymaps to appropriate `lua/plugins/keymaps/*/` module
4. Use lazy loading with appropriate events/commands/keys

### Plugin Specification Pattern
```lua
{
  "author/plugin-name",
  event = "VeryLazy",        -- Lazy loading trigger
  dependencies = { ... },     -- Plugin dependencies
  opts = function()
    return require("plugins.config.plugin-name")
  end,
  keys = { ... }             -- Keymap definitions
}
```

### Keymap Organization Pattern
- 所有快捷键在 `all.lua` 集中定义
- 复杂回调函数放在 `functions.lua`
- 使用 which-key 的 table 格式：`{ "<leader>xx", fn.xxx, desc = "Description" }`
- 按 `<leader>` 前缀分组，便于查看冲突

## Important Development Notes

### Keymap Preferences
- **不使用大写字母快捷键**：所有 `<leader>` 快捷键只用小写字母，避免 Shift 组合
- 新增快捷键时优先使用未占用的小写字母

### Code Comments
Configuration uses Chinese comments extensively - this is intentional and should be preserved.

### Modern Neovim APIs
Uses Neovim 0.11+ features like `vim.lsp.config()` instead of deprecated patterns. When modifying LSP configurations, maintain compatibility with the new API structure.

### Auto-reload Behavior
File changes are automatically detected and configuration is reloaded. The `lua/core/reload.lua` module handles configuration reloading.

### Input Method Switching
Special integration for input method switching on macOS (`lua/core/im-switch.lua`) - handles automatic switching between input methods when entering/leaving insert mode.

## Troubleshooting

### Plugin Issues
- Check `:checkhealth` for configuration problems
- Review `:Lazy` for plugin loading issues
- Examine `:LspInfo` for language server status

### Environment Variables
- Ensure `.env` file exists with required variables
- Check environment loading with `:lua print(vim.inspect(require('core.env').get_all()))`

### Performance
- Use `:Lazy profile` to identify slow-loading plugins
- Most plugins use lazy loading - verify event triggers are appropriate