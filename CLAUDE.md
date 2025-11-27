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
Keymaps are organized by functional areas with conditional loading:

```
keymaps/
├── editor/     # Navigation, window management, terminal
├── tools/      # Telescope, FZF, nvim-tree
├── git/        # Git operations
├── lsp/        # Language server operations
├── debug/      # DAP debugging
└── project/    # Testing, task management, folding
```

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
- **toggleterm**: Terminal management
- **possession**: Session management

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
- Group by functional area (editor, tools, git, etc.)
- Use aggregator `init.lua` files to load submodules
- Environment-conditional loading in root keymap init.lua

## Important Development Notes

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