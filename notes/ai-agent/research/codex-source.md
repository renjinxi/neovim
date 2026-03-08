# Codex 源码研究

来源: https://github.com/openai/codex
技术栈: Rust (主体) + TypeScript (旧版/SDK)
规模: 50+ Rust crates

## 项目结构

```
codex/
├── codex-rs/              # Rust 主体
│   ├── core/              # 核心引擎（session/turn/tool）
│   ├── cli/               # CLI 入口
│   ├── tui/               # 终端 UI（Ratatui）
│   ├── exec/              # 无头执行模式
│   ├── app-server/        # JSON-RPC server（给 IDE 用）
│   ├── mcp-server/        # Codex 作为 MCP server
│   ├── rmcp-client/       # Codex 作为 MCP client
│   ├── protocol/          # 通信协议定义
│   ├── linux-sandbox/     # Linux Landlock 沙箱
│   ├── windows-sandbox-rs/# Windows 沙箱
│   ├── network-proxy/     # 网络策略
│   ├── state/             # 会话持久化
│   ├── rollout/           # 对话历史记录
│   ├── skills/            # 技能发现
│   ├── plugins/           # 插件系统
│   └── stdio-to-uds/     # stdio ↔ Unix socket 中继
├── codex-cli/             # 旧版 TypeScript CLI（已废弃）
├── shell-tool-mcp/        # 沙箱 shell MCP server
└── sdk/typescript/        # TypeScript SDK
```

## 核心架构：生产者-消费者队列

```
用户输入 → Op（操作） → Submission Queue (128)
                              ↓
                        Codex Engine
                              ↓
                  Event Queue → UI 渲染
```

Op = UI → Engine 的指令（UserTurn / Interrupt / ExecApproval）
EventMsg = Engine → UI 的事件（TurnStarted / AgentMessage / TurnComplete）

关键：UI 和 Engine 完全解耦，通过 async_channel 通信。

## 对我们最有价值的发现

### 1. 内置多 Agent 协作（Collab 特性）

Codex 原生支持 agent 之间的协作：

```rust
// 协作工具
spawn_agent(message, items, agent_type, fork_context)  // 创建子 agent
send_input(id, message, items, interrupt)               // 给子 agent 发消息
wait(id, timeout_ms)                                    // 等子 agent 完成
resume_agent(id)                                        // 恢复子 agent
close_agent(id)                                         // 关闭子 agent
```

特点：
- 父子层级关系，父 agent 控制子 agent
- 子 agent 继承父的 config、sandbox、provider、cwd
- 有深度限制防止无限递归
- 子 agent 的事件会冒泡到父 agent

**但这是进程内的**：所有 agent 在同一个 Codex 进程里，是线程级别的协作，不是跨进程通信。

### 2. App Server — IDE 集成的 JSON-RPC

```
IDE ←→ app-server (JSON-RPC 2.0 over stdio/WebSocket) ←→ Codex Engine
```

API：
- `thread/start`, `thread/resume`, `thread/fork`
- `turn/start`, `turn/steer`, `turn/interrupt`
- `command/exec`（一次性命令执行）

传输：
- 默认 stdio（换行分隔 JSON）
- 可选 WebSocket（实验性）

**这就是 Codex 版的 SDK-URL 模式**。IDE 通过 app-server 控制 Codex，和 Claude Code 的 sdk-url 思路一样。

### 3. MCP 双向集成

Codex 同时是 MCP client 和 MCP server：

作为 client：
- 连接外部 MCP server
- 工具名格式：`mcp__<server>__<tool>`
- 管理多个 MCP server 连接

作为 server：
- `codex mcp-server` 启动
- JSON-RPC 2.0 over stdio
- 暴露 Codex 的能力给其他工具

### 4. PTY 管理

```
codex-rs/core/src/tools/runtimes/shell/
├── shell.rs              # Shell 运行时
├── unix_escalation.rs    # Unix 沙箱集成
└── ...

codex-rs/utils/pty/       # 跨平台 PTY
├── unix.rs               # Unix PTY
└── windows.rs            # Windows ConPTY
```

Shell 执行后端：
- Classic — 标准 shell 调用
- ZshFork — zsh 级别的沙箱拦截
- UnifiedExec — PTY 统一执行

### 5. 沙箱架构

| 平台 | 技术 |
|------|------|
| macOS | Seatbelt (sandbox-exec) |
| Linux | Landlock LSM |
| Windows | Job objects + AppContainer |

策略级别：read-only / workspace-write / danger-full-access

### 6. 状态持久化

- SQLite 存元数据（线程索引、turn 元数据、git 信息、记忆）
- JSONL 存对话历史（rollout）
- 支持从 bookmark 恢复会话

## 和 Claude Code 的对比

| | Codex | Claude Code |
|---|---|---|
| 语言 | Rust | TypeScript |
| 多 agent | 进程内线程级 | 独立进程 + 共享任务列表 |
| IDE 集成 | app-server (JSON-RPC) | sdk-url (WebSocket) |
| MCP | client + server | client |
| 沙箱 | OS 级别（Landlock/Seatbelt） | 文件系统级别 |
| 状态 | SQLite + JSONL | JSONL |
| 扩展 | plugins + skills | hooks + MCP |
| 通信协议 | Op/EventMsg 队列 | 内部事件 |

## 对我们 AI-to-AI 目标的启发

### 可以借鉴的

1. **Op/Event 队列模型** — 干净的双向通信抽象，UI 和 Engine 解耦
2. **app-server 模式** — 通过 JSON-RPC 程序化控制 AI CLI，不依赖 terminal 解析
3. **MCP server 模式** — Codex 自己可以作为 MCP server 被其他工具调用
4. **多 agent 工具** — spawn_agent / send_input / wait 的 API 设计很清晰

### 不能直接用的

1. **多 agent 是进程内的** — 不是跨进程通信，不能让两个独立 Codex 实例互相通信
2. **app-server 面向 IDE** — 设计给 VS Code 用，不是给另一个 AI 用
3. **没有 agent-to-agent 协议** — Codex 实例之间没有通信机制

### 关键洞察

Codex 的 `codex mcp-server` 模式意味着：
- 理论上可以让一个 AI（如 Claude Code）通过 MCP 调用 Codex
- Codex 暴露自己的能力为 MCP tools
- 但这是单向的（调用方 → Codex），不是双向通信

Codex 的 app-server 模式意味着：
- 可以写一个中间层，通过 JSON-RPC 控制 Codex
- 类似 Claude Code 的 sdk-url，但用 stdio 而不是 WebSocket
- 人可以通过 TUI 直接交互，也可以通过 app-server 程序化控制

## 结论

Codex 是一个工程质量极高的 AI CLI，但它的多 agent 是"一个大脑多个手"模式（进程内线程），不是"多个大脑互相通信"模式（跨进程）。

对我们最有价值的是：
1. **app-server 的 JSON-RPC 接口** — 程序化控制 Codex 的标准方式
2. **MCP server 模式** — 让 Codex 被其他 AI 工具调用
3. **Op/Event 协议设计** — 干净的双向通信模型可以参考
