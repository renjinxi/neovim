# Neovim Configuration

现代 Neovim 配置，核心探索方向是 **ACP（Agent Communication Protocol）多 AI 协作系统**。

## ACP 频道系统

在 Neovim 中实现多 AI agent 协作：你在编辑器前，主 agent 是你的助手，子 agent 是它派出去干活的。频道是所有通信的可见层，人类随时介入。

```
你（nvim 前）
  │
  └── 主 agent (AcpChat)
        │
        ▼
      频道 (Channel)
        ├── 子 agent-1 (claude)
        ├── 子 agent-2 (codex)
        └── 子 agent-N (gemini)
```

### 已实现能力

- **协议层**：JSON-RPC 2.0 + ACP 握手 + 多 adapter（claude/c1/c2/gemini/codex）
- **频道通信**：共享消息空间 + @mention 路由 + 人类直接参与
- **Chat UI**：独立 1v1 对话窗口 + 频道消息联动
- **可观测性**：agent 状态 winbar + Telescope picker + 独立 chat buffer
- **命令系统**：`/add` `/stop` `/list` `/open` `/pick` `/status` `/cancel` `/exit` `/leave`
- **持久化**：频道快照保存/恢复
- **长消息文件化**：>300 字自动写文件，频道只显示摘要
- **健康监控**：双通道状态检测（ACP + RPC 回调），streaming 超时警告

### 里程碑

| 阶段 | 内容 | 状态 |
|------|------|------|
| M0 | 基础通信 — 协议层、单 agent 对话 | ✅ |
| M1 | 频道协作 — 多 agent、@mention 路由、架构重构 | ✅ |
| M2 | 任务层 — task 对象、结构化协作原语、可观测面板 | 设计中 |
| M3 | 自主扩展 — 子 agent spawn 新 agent | 规划中 |
| M4 | 频道树 — 频道嵌套、子频道汇报父频道 | 规划中 |
| M5 | 远程 Agent — HTTP/WebSocket transport | 规划中 |

### 使用

```vim
" 打开 Chat
:Acp chat claude
:Acp chat gemini

" 频道操作
:Acp open              " 打开频道
:Acp pick              " Telescope agent 选择器
:Acp leave <name>      " agent 退出频道

" 频道输入框命令（/ 开头）
/add claude reviewer   " 添加 agent
/list                  " 列出所有 agent
/stop <name>           " 停止 agent
```

### 架构（17 模块）

```
lua/acp/
├── init.lua          # 公共 API + :Acp 命令
├── channel.lua       # 频道核心（消息、agent 管理、路由）
├── channel_view.lua  # 频道 UI（buffer 渲染、winbar、输入框）
├── bus.lua           # 频道 facade（向后兼容入口）
├── router.lua        # @mention 路由逻辑
├── scheduler.lua     # agent 调度 + main 推送队列
├── task.lua          # 任务数据模型
├── agent.lua         # agent 数据结构
├── registry.lua      # 全局频道注册表
├── chat.lua          # 1v1 Chat UI
├── client.lua        # ACP 协议客户端（握手/prompt/stream）
├── jsonrpc.lua       # JSON-RPC 2.0 编解码
├── adapter.lua       # adapter 配置（claude/gemini/codex）
├── commands.lua      # 输入框命令系统
├── picker.lua        # Telescope agent picker
├── rpc.lua           # nvim RPC 入口（供外部调用）
└── store.lua         # 频道持久化
```

### 项目文档

- 问题清单：`notes/acp-channel/issues.md`
- 里程碑规划：`notes/acp-channel/roadmap.md`
- 架构设计：`notes/acp-channel/design/`
- 调研资料：`notes/acp-channel/research/`

## Neovim 配置概览

90+ 插件，Lazy.nvim 管理，支持 native Neovim 和 VSCode/Cursor 双环境。

- **LSP**：15+ 语言服务器（Mason 自动安装）
- **补全**：nvim-cmp + luasnip
- **调试**：nvim-dap（Python/C++/Go/JS）
- **导航**：Telescope + Flash + nvim-tree
- **Git**：Neogit + LazyGit + gitsigns + diffview
- **UI**：Rose Pine 主题 + Heirline 状态栏
- **任务**：Overseer + Neotest

### 目录结构

```
lua/
├── core/           # 基础配置（options/autocmds/env）
├── plugins/        # 插件生态
│   ├── plugins/    # 插件声明（lazy.nvim specs）
│   ├── config/     # 插件配置（35+ 文件）
│   ├── keymaps/    # 快捷键（all.lua 集中管理）
│   └── dap/        # 调试配置
├── acp/            # ACP 频道系统（见上）
└── user/           # 用户自定义
```
