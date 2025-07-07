# Claude Code Neovim 插件配置指南

## 简介
claude-code.nvim 是一个让 Neovim 与 Claude Code AI 助手无缝集成的插件。它提供了在终端窗口中直接与 Claude Code 交互的能力，并能自动检测和重新加载被 Claude Code 修改的文件。

## 安装要求
1. **Neovim 0.7.0** 或更高版本
2. **Claude Code CLI 工具** 已安装并在 PATH 中可用
3. **plenary.nvim** 依赖（已在配置中包含）

## 主要功能
- 🚀 一键切换 Claude Code 终端窗口
- 🧠 支持命令行参数如 `--continue` 和自定义变体
- 🔄 自动检测并重新加载被 Claude Code 修改的文件
- ⚡ 实时缓冲区更新
- 📱 可自定义的窗口位置和大小（包括浮动窗口）
- 🤖 与 which-key 集成
- 📂 自动使用 git 项目根目录作为工作目录

## 配置详情
插件已配置在 `lua/plugins/config/claude-code.lua` 中，主要设置包括：

### 窗口设置
- **split_ratio**: 0.4 (终端窗口占 40% 屏幕)
- **position**: "botright" (右下角分割)
- **enter_insert**: true (自动进入插入模式)

### 文件刷新设置
- **enable**: true (启用文件更改检测)
- **updatetime**: 100ms (检查间隔)
- **show_notifications**: true (显示重新加载通知)

## 按键映射

### 基本操作
- `<leader>cc` - 切换 Claude Code 终端
- `<C-,>` - 切换 Claude Code 终端（普通模式和终端模式）
- `<leader>cx` - 取消当前 Claude Code 请求

### 对话管理
- `<leader>cC` - 恢复最近的对话 (--continue)
- `<leader>cr` - 显示对话选择器 (--resume)
- `<leader>cV` - 启用详细日志模式 (--verbose)

### 消息导航
- `]c` - 跳转到下一条消息
- `[c` - 跳转到上一条消息

### 其他功能
- `<leader>ci` - 导入 Claude Workbench 对话
- `<leader>cn` - 重新显示上次通知
- `<C-s>` (插入模式) - 发送并返回插入模式

### 日志管理
- `<leader>cel` - 启用日志记录
- `<leader>cdl` - 禁用日志记录
- `<leader>col` - 打开日志文件

## 使用方法

### 基本使用
1. 在 Neovim 中按 `<leader>cc` 或 `<C-,>` 打开 Claude Code 终端
2. 在终端中输入你的问题或命令
3. Claude Code 会自动检测并重新加载被修改的文件
4. 使用 `<C-,>` 关闭终端窗口

### 浮动窗口模式
如果你想使用浮动窗口而不是分割窗口，可以修改 `lua/plugins/config/claude-code.lua` 中的配置：

```lua
window = {
    position = "float",
    float = {
        width = "90%",
        height = "90%",
        row = "center",
        col = "center",
        border = "rounded",
    },
},
```

### 对话管理
- 使用 `<leader>cC` 继续上次的对话
- 使用 `<leader>cr` 从多个对话中选择
- 使用 `<leader>cV` 启用详细输出模式

### 窗口导航
当 Claude Code 终端打开时，你可以使用：
- `<C-h/j/k/l>` - 在窗口间移动
- `<C-f/b>` - 在终端中翻页

## 故障排除

### 常见问题
1. **命令未找到**: 确保 Claude Code CLI 工具已安装并在 PATH 中
2. **文件未自动重新加载**: 检查 `refresh.enable` 设置是否为 true
3. **按键映射冲突**: 可以在配置文件中禁用默认按键映射并设置自定义映射

### 调试
使用以下命令启用日志记录来调试问题：
```vim
:ClaudeCodeEnableLogging
" 复现问题后
:ClaudeCodeOpenLog
" 查看完毕后禁用日志
:ClaudeCodeDisableLogging
```

## 自定义配置

### 禁用默认按键映射
如果你想使用自定义按键映射，可以在配置中设置：
```lua
keymaps = {
    enabled = false  -- 禁用所有默认按键映射
}
```

### 自定义终端位置
你可以将终端位置设置为：
- "botright" - 右下角（默认）
- "topleft" - 左上角
- "vertical" - 垂直分割
- "float" - 浮动窗口

## 更新配置
修改配置后，重新启动 Neovim 或执行 `:Lazy reload claude-code.nvim` 来应用更改。

## 获取帮助
如果遇到问题，可以：
1. 查看插件的 GitHub 仓库：https://github.com/greggh/claude-code.nvim
2. 启用日志记录并查看错误信息
3. 检查 Claude Code CLI 工具是否正确安装

---

这个插件配置已经为你的 Neovim 环境进行了优化，包含了中文注释和合理的默认设置。开始使用 Claude Code 来提升你的开发体验吧！ 