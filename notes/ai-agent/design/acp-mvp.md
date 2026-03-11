# ACP MVP 梳理

## 现状

PTY 方案到极限了。转 ACP 结构化通信，全部 agent 都通过 ACP 启动（不再有 PTY 终端模式）。

## 核心理念

**像群聊一样协作。**

所有 agent 通过 ACP 启动，接入同一个频道。agent 闷头干活，需要通信时主动发消息到频道。人类通过频道 buffer 全程可见、随时介入。

没有固定的 coordinator 角色。谁先在、谁发起任务、谁启动别人，谁自然就是协调者。任何 agent 都可以启动新 agent、给别人分任务。

## 频道机制

频道是个哑管道，不做智能判断。

### agent 拥有的 3 个 MCP tool

| tool | 作用 |
|------|------|
| `bus_post(content)` | 发消息到频道。内容里可以 @agent-name 指定接收者 |
| `bus_read(last_n)` | 主动拉取频道最近 N 条消息 |
| `bus_spawn(type, prompt)` | 启动一个新 agent，自动接入频道 |

### 频道路由规则

```
消息进来（bus_post）
  ↓
追加到消息列表，渲染到 nvim buffer（人类始终可见）
  ↓
检查有没有 @
  ├── 有 @agent-name → 推送给被 @ 的 agent（往它的 ACP stdin 发 user message）
  └── 没有 @ → 只放在频道里，不推给任何人
```

agent 被 @ 时不会被打断——ACP 是消息队列，推送的消息排队，等它当前 turn 结束后才处理。

agent 想主动看频道历史，调 `bus_read()`。不调就看不到没 @ 自己的消息。

人类在频道 buffer 里打字，和 agent 一样的规则——有 @ 就推，没 @ 就放着。

### 频道 UI

```
┌─────────────────────────────────────┐
│ 频道 buffer                          │
│                                     │
│ [你]       加 JWT 认证 @agent-1      │
│ [agent-1]  收到，我来拆任务           │
│ [agent-1]  @agent-2 写 middleware    │
│ [agent-1]  @agent-3 写测试           │
│ [agent-2]  开始写 middleware          │
│ [agent-2]  middleware 写完了          │
│ [agent-3]  token 策略不确定 @agent-1  │
│ [agent-1]  @agent-3 用 rotation      │
│ [你]       过期时间改 7 天 @agent-2   │
│                                     │
│ > 输入框 _                           │
└─────────────────────────────────────┘
```

## 完整流程示例

```
第 1 步：你在 nvim 里启动第一个 agent
  :AcpStart claude
  → nvim spawn Claude CLI (ACP/sdk-url)
  → agent-1 上线，接入频道

第 2 步：你在频道 buffer 里打字
  "给项目加 JWT 认证 @agent-1"
  → 频道推送给 agent-1

第 3 步：agent-1 思考，决定要帮手
  agent-1 调 bus_spawn("claude", "你负责写 auth middleware")  → agent-2 上线
  agent-1 调 bus_spawn("claude", "你负责写测试")              → agent-3 上线
  agent-1 调 bus_post("任务分配完了，agent-2 写代码，agent-3 写测试")

第 4 步：agent-2、agent-3 闷头干活
  （内部：读代码、写代码、跑测试... 这些不进频道）

第 5 步：关键节点才发消息
  agent-2 调 bus_post("middleware 写完了")
  agent-3 调 bus_post("token 策略不确定 @agent-1")

第 6 步：agent-1 协调
  agent-1 看到 agent-3 的 @，回复：bus_post("@agent-3 用 rotation")

第 7 步：你随时介入
  你在频道 buffer 打字："过期时间改 7 天 @agent-2"
  → 频道推送给 agent-2，它下个 turn 处理

第 8 步：全部完成
  agent-2 调 bus_post("已改，done")
  agent-3 调 bus_post("测试全过，done")
  agent-1 调 bus_post("全部完成 @你")
```

## 架构

```
nvim
│
├── lua/acp/
│   ├── init.lua           # 入口，:AcpStart / :AcpBus 命令注册
│   ├── client.lua         # ACP 协议层，spawn / send / receive
│   ├── adapters/
│   │   ├── claude.lua     # Claude --sdk-url adapter（通过 ws-proxy）
│   │   ├── gemini.lua     # Gemini --acp adapter（直连 stdio）
│   │   └── codex.lua      # Codex app-server adapter（后续）
│   ├── bus.lua            # 频道：消息列表 + @路由 + MCP tool 注册
│   └── ui.lua             # 频道 buffer 渲染 + 输入框
│
├── proxy/
│   └── ws-bridge.js       # Claude 用的 WS proxy（nvim ↔ stdio ↔ WS ↔ CLI）
│
└── 和 core/plugins 平级，独立目录
```

### 各层职责

| 层 | 做什么 | 不做什么 |
|----|--------|---------|
| adapter | 屏蔽协议差异（WS/ACP/stdio），统一接口 | 不关心消息内容 |
| client | spawn agent、发消息、收回复、注册 MCP tool | 不关心频道逻辑 |
| bus | 消息列表、@路由、推送 | 不做智能判断、不做任务编排 |
| ui | 渲染频道 buffer、处理人类输入 | 不做消息路由 |

### Claude Code 的 ACP 问题

Claude Code 没有原生 ACP，只有 `--sdk-url`（WebSocket NDJSON）。

解决方案：外挂一个 ws-proxy 进程，nvim 通过 stdio 和 proxy 通信，proxy 通过 WS 和 Claude CLI 通信。

```
nvim ←(stdio JSON)→ ws-proxy ←(WebSocket NDJSON)→ Claude CLI (--sdk-url)
```

这样 adapter 层看到的都是 stdio JSON，不管底层是 WS 还是原生 ACP。

ws-proxy 可以直接从 Companion 项目抄，用 Bun 或 Node。

## MVP 里程碑

### M0：单 agent + 频道（最小可用）

目标：nvim 里启动一个 Claude，通过频道 buffer 和它对话。

要做的事：
1. ws-proxy 脚本（抄 Companion）
2. `adapters/claude.lua` — spawn proxy + CLI
3. `bus.lua` — 消息列表（单 agent 时就是一对一聊天）
4. `ui.lua` — 频道 buffer + 输入框
5. 权限：默认全部允许（`--dangerously-skip-permissions` 或自动 approve）

不做：多 agent、bus_spawn、@路由、Gemini/Codex

### M1：多 agent + 频道路由

目标：多个 agent 通过频道协作。

要做的事：
1. `bus_spawn` MCP tool — agent 能启动新 agent
2. @路由 — 频道按 @ 推送消息
3. `bus_read` MCP tool — agent 主动拉取频道历史
4. 多 agent 生命周期管理

### M2：adapter 扩展

目标：加 Gemini 支持。

要做的事：
1. `adapters/gemini.lua` — `vim.uv.spawn` + pipe，ACP JSON-RPC
2. `client.lua` 统一接口验证
3. 混合编排：Claude + Gemini 在同一个频道

### M3：UI 完善 + 生产可用

- 频道 buffer markdown 渲染
- agent 状态指示（idle/working/done）
- 状态栏集成（heirline）
- 快捷键体系
- session 持久化

## 需要调研的开源项目

### M0 必看

| 项目 | 抄什么 | 链接 |
|------|--------|------|
| Companion | ws-proxy 实现、Claude --sdk-url 协议处理 | [GitHub](https://github.com/The-Vibe-Company/companion) |
| codecompanion.nvim | nvim chat buffer 渲染、ACP client、adapter pattern | [GitHub](https://github.com/olimorris/codecompanion.nvim) |

### M1 需要

| 项目 | 抄什么 | 链接 |
|------|--------|------|
| acpx | headless ACP client 会话管理 | [GitHub](https://github.com/nicholasgasior/acpx) |
| agent-team | 多 agent ACP 编排、角色系统 | [GitHub](https://github.com/nekocode/agent-team) |

### M2 需要

| 项目 | 抄什么 | 链接 |
|------|--------|------|
| Gemini CLI 源码 | ACP 消息格式、--acp 启动参数 | [GitHub](https://github.com/google-gemini/gemini-cli) |

### 通用参考

| 项目 | 关注点 | 链接 |
|------|--------|------|
| Claude Code team 模式 | 主从协作、SendMessage 路由 | 本地 claude 源码 |
| ACP 协议规范 | 完整消息类型、tool 注册 | [GitHub](https://github.com/zed-industries/agent-client-protocol) |

## 和现有系统的关系

| 现有 | 新系统 | 关系 |
|------|--------|------|
| agent_api.lua (PTY) | acp/ 模块 | 共存，PTY 保留给简单场景，逐步迁移 |
| task_watcher.lua | bus.lua | bus 替代 task_watcher |
| ai-task-dispatch skill | :AcpStart 命令 | 逐步迁移 |
| nvim-instance-agent skill | 保留 | ACP agent 仍可能需要 RPC 控制 nvim |

## 待确认

- [ ] `--sdk-url` 模式下能否通过 `--mcp-config` 给 agent 注册自定义 MCP tool（bus_post 等）
- [ ] ACP 协议里 tool registration 的具体机制
- [ ] ws-proxy 和 nvim 之间的 stdio 消息格式定义
- [ ] agent 被 @ 时，消息怎么注入到它的 ACP 会话（作为新的 user message？追加到 system prompt？）
