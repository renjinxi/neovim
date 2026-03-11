# Forge 研究笔记

仓库：https://github.com/forge-agents/forge
代码位置：`/tmp/acp-research/forge`

## 一句话总结

Forge 是一个 ACP 协议的 TUI 客户端，通过 subprocess + ndjson stdio 管理多个 coding agent。**没有多 agent 协作/消息路由**，本质是"一次用一个 agent"的切换器。

## 架构

```
TUI (Solid.js + OpenTUI)
  ↓ HTTP (Hono)
Server (session/config/event 管理)
  ↓
ACPOrchestrator (每 session 一个 agent)
  ↓
ACPClient (subprocess + ndjson stdio)
  ↓
Agent 子进程 (claude-code-acp / gemini / codex-acp / ...)
```

核心依赖：`@agentclientprotocol/sdk@0.5.1`

## ACP Client 实现

文件：`packages/forge/src/acp/client.ts`

关键流程：
1. `Bun.spawn([command, ...args])` 启动 agent 子进程
2. stdin/stdout 用 `ndJsonStream()` 包装成双向 JSON-RPC 通道
3. `ClientSideConnection` (来自 ACP SDK) 处理协议层
4. 生命周期：`initialize() → authenticate() → createSession() → sendPrompt() → dispose()`

通信协议：**ndjson over stdio**，不是 HTTP/WebSocket。每行一个 JSON-RPC 消息。

```typescript
// 核心创建逻辑
const proc = Bun.spawn([config.command, ...(config.args ?? [])], {
  stdin: "pipe", stdout: "pipe", stderr: "pipe",
  env: { ...process.env, ...config.env },
  cwd: config.cwd,
})
const stream = ndJsonStream(stdinWritable, proc.stdout)
const connection = new ClientSideConnection((_agent) => clientImpl, stream)
```

## Agent 注册表

文件：`packages/forge/src/acp/registry/`

- 从 CDN 拉取：`https://cdn.agentclientprotocol.com/registry/v1/latest/registry.json`
- 本地缓存 24h：`~/.cache/forge/acp-registry.json`
- 每个 agent 定义包含：name, command, args, distribution (npx/uvx/binary)

## 对接不同 CLI 的方式

**关键发现：Claude Code 和 Codex 不是 ACP 原生的。**

它们通过 Zed 的 ACP wrapper 适配：
- Claude → `@zed-industries/claude-code-acp` (npm 包，包装 claude CLI)
- Codex → `@zed-industries/codex-acp` (npm 包，包装 codex CLI)
- Gemini → 原生支持 ACP

每个 agent 的差异通过 registry 的 distribution 字段描述：
```typescript
interface Agent {
  distribution: {
    npx?: { package: string, args?: string[], env?: Record<string, string> }
    uvx?: { package: string, args?: string[], env?: Record<string, string> }
    binary?: Record<PlatformKey, { archive: string, cmd: string, args?: string[] }>
  }
}
```

Forge 统一用 `Bun.which(command)` 检测是否已安装，用 `Bun.spawn` 启动。

## 多 Agent 协作？

**没有真正的多 agent 协作。**

`ACPOrchestrator` 的设计是 `Map<sessionID, SessionState>`，每个 session 同时只有一个 agent。

所谓的 "agent queue"（`--agent` flag）只是顺序切换：
- 用户可以指定 `--agent "name=claude mode=plan" --agent "name=gemini"`
- 当 agent 的 mode 变化时（比如 plan → build），自动切换到队列中的下一个 agent
- 切换时会 dispose 旧 client，创建新 client

没有：
- agent 间消息传递
- 并行运行多个 agent
- agent 间任务分发/协调

## ACP 协议要点

从代码中提取的 ACP 协议核心概念：

### Session Notifications (agent → client)
- `agent_message_chunk` — 文本流式输出
- `agent_thought_chunk` — 推理/思考过程
- `tool_call` / `tool_call_update` — 工具调用及状态更新
- `plan` — 任务计划（完整替换语义）
- `current_mode_update` — mode 变更通知
- `available_commands_update` — 可用命令更新

### Client → Agent 操作
- `initialize` — 握手，交换 capabilities
- `newSession` — 创建会话，传入 cwd + MCP servers
- `prompt` — 发送用户消息
- `cancel` — 取消当前 turn
- `setSessionMode` / `setSessionModel` — 切换 mode/model
- `authenticate` — 认证

### Permission 系统
Agent 可以请求权限（`requestPermission`），client 弹窗让用户选择 allow/reject。

## Translator 层

文件：`packages/forge/src/acp/translator.ts` + `translation/`

将 ACP 的 SessionNotification 翻译成 Forge 内部的 MessageV2 格式：
- text chunk → TextPart（累积拼接）
- thought chunk → ReasoningPart
- tool_call → ToolPart（pending → running → completed/error）
- plan → Plan entries

这层是纯适配，没有额外逻辑。

## 对我们的价值

### 可直接参考的
1. **ndjson stdio 通信模式** — 比 HTTP 简单，适合本地 subprocess 场景
2. **Agent registry + CDN** — agent 发现和安装的标准化方式
3. **ACP SDK 的 `ClientSideConnection`** — 如果我们要做 ACP client，直接用这个 SDK
4. **Permission 请求/响应模式** — agent 请求权限，client 决策

### 不适用的
1. **没有多 agent 协作** — 我们需要的 agent 间通信、任务分发，Forge 完全没做
2. **Bun 绑定** — 整个项目深度依赖 Bun runtime，不能直接搬
3. **TUI 架构** — Solid.js + OpenTUI，和我们的 nvim 场景无关

### 关键启发
- ACP 协议本身是 **client-agent 1:1** 的，不包含 agent-to-agent 通信
- 如果要做多 agent 协作，需要在 ACP 之上自己加一层编排
- Zed 的 claude-code-acp wrapper 是个有趣的思路：把非 ACP 的 CLI 包装成 ACP 兼容
- `@agentclientprotocol/sdk@0.5.1` 是目前最新的 JS SDK，协议版本通过 `PROTOCOL_VERSION` 常量管理
