# Claude Code --sdk-url WebSocket 协议

> 来源：[The-Vibe-Company/companion](https://github.com/The-Vibe-Company/companion) 逆向工程
> 基于 Claude Code CLI v2.1.37 + Agent SDK v0.2.37

## 核心机制

Claude Code CLI 有隐藏 `--sdk-url <ws-url>` flag，CLI 作为 WS client 连回你的 server，协议是 NDJSON（换行分隔 JSON）。

## 启动命令

```bash
claude --sdk-url ws://localhost:8765/ws/{session-id} \
       --print \
       --output-format stream-json \
       --input-format stream-json \
       --verbose \
       -p ""
```

| Flag | 必须 | 说明 |
|------|------|------|
| `--sdk-url <url>` | 是 | WS 地址，CLI 主动连过来 |
| `--print` / `-p ""` | 是 | headless 模式，prompt 占位符被忽略 |
| `--output-format stream-json` | 是 | NDJSON 输出 |
| `--input-format stream-json` | 是 | NDJSON 输入 |
| `--verbose` | 否 | 开启 stream_event（逐 token） |
| `--model <model>` | 否 | 指定模型 |
| `--permission-mode <mode>` | 否 | 权限模式 |
| `--resume <session-id>` | 否 | 恢复会话 |
| `--include-partial-messages` | 否 | 新版需要，开启流式 chunk |

## 连接生命周期

```
Your Server                              Claude Code CLI
    │                                         │
    │◄──── WebSocket CONNECT ─────────────────│  (带 Auth header)
    │                                         │
    │◄──── system/init ───────────────────────│  (session_id, model, cwd, tools)
    │                                         │
    │──── user message ───────────────────────►│  (发 prompt)
    │                                         │
    │◄──── stream_event ──────────────────────│  (逐 token，需 --verbose)
    │◄──── assistant ─────────────────────────│  (完整回复)
    │                                         │
    │◄──── control_request (can_use_tool) ────│  (需要权限)
    │──── control_response (allow/deny) ──────►│  (审批)
    │                                         │
    │◄──── result ────────────────────────────│  (turn 结束，含 cost/usage)
```

## 消息类型

### CLI → Server

| type | 说明 |
|------|------|
| `system` (init) | 初始化：session_id, model, cwd, tools, mcp_servers, permissionMode |
| `system` (status) | 状态变化（compacting 等） |
| `assistant` | 完整 assistant 回复（含 content blocks） |
| `stream_event` | 流式 token（需 --verbose） |
| `result` | turn 结束：cost, usage, num_turns, lines_added/removed |
| `control_request` | 权限请求（subtype: can_use_tool） |
| `tool_progress` | tool 执行进度 |
| `tool_use_summary` | tool 使用摘要 |
| `keep_alive` | 心跳 |

### Server → CLI

| type | 说明 |
|------|------|
| `user` | 用户消息：`{"type":"user","message":{"role":"user","content":"..."}}`  |
| `control_response` | 权限回复：allow/deny |
| `control_request` | 控制指令：interrupt / set_model / set_permission_mode |

### control_request 权限审批

```json
// CLI 请求
{"type":"control_request","request_id":"xxx","request":{"subtype":"can_use_tool","tool_name":"Bash","input":{...},"description":"..."}}

// Server 批准
{"type":"control_response","response":{"subtype":"success","request_id":"xxx","response":{"behavior":"allow"}}}

// Server 拒绝
{"type":"control_response","response":{"subtype":"success","request_id":"xxx","response":{"behavior":"deny","message":"reason"}}}
```

## Companion 架构

```
Browser (React) ←→ WS ←→ Hono Server (Bun) ←→ WS (NDJSON) ←→ Claude Code CLI
     :5174        /ws/browser/:id    :3456      /ws/cli/:id       (--sdk-url)
```

关键文件：
- `web/server/cli-launcher.ts` — spawn CLI 进程，传 --sdk-url
- `web/server/ws-bridge.ts` — 消息路由，CLI↔Browser 桥接
- `web/server/session-types.ts` — 完整类型定义
- `WEBSOCKET_PROTOCOL_REVERSED.md` — 协议逆向文档（~50KB）

## 对比现有 task system

| | 文件通信 (现有) | --sdk-url (WS) |
|---|---|---|
| 通信方式 | status/result.md 文件 | WebSocket NDJSON |
| 控制粒度 | 只能发任务描述 | 逐消息、逐 tool call |
| 权限控制 | 需 --dangerously-skip-permissions | 实时 approve/deny |
| 流式输出 | 无 | stream_event 逐 token |
| 会话恢复 | 无 | --resume + cliSessionId |
| 状态感知 | fs_event 轮询 status 文件 | 实时 WS 推送 |
| 多 agent 通信 | 不支持 | 通过 server bridge 可互发 |

## nvim 集成思路

1. nvim 起 WS server（vim.uv tcp + WS 握手，或外挂轻量进程）
2. spawn claude 时传 `--sdk-url ws://localhost:{port}/ws/{task-id}`
3. NDJSON 协议控制：发 prompt、审批 tool、读流式输出、中断
4. 不再需要：`\r` hack、skip-permissions、文件轮询

## nvim 内实现交互界面

`--sdk-url` 模式下 CLI 是 headless 的，没有自带交互界面，所有交互需要自己实现。
但协议已经把脏活干完了，实际要做的不多。

### 需要实现的三个核心交互

1. **看输出** — assistant 回复写入 buffer，stream_event 逐 token 追加，buffer 自动滚动
2. **发消息** — input 框发 `user` 消息给 CLI
3. **审批 tool** — `control_request` 来了弹浮动窗口，显示 tool_name + input，y/n 回复

### 实现方案

nvim buffer 天然就是文本展示器，比浏览器画 React 组件还简单：

- **消息展示**：专用 buffer，markdown 高亮，assistant/user 消息分块显示
- **权限弹窗**：收到 `control_request` → `vim.ui.select` 或浮动窗口显示 tool 详情 → y/n 回 `control_response`
- **输入框**：底部 prompt input，回车发送
- **流式输出**：`stream_event` 逐 token 追加到 buffer 末尾，实时可见 Claude 在干什么

### WS 层方案选择

lua 原生做 WS 握手比较麻烦（要处理 HTTP upgrade、frame masking 等），两个路线：

1. **外挂轻量进程**（推荐）— 小 node/bun 脚本做 WS proxy，nvim 通过 stdin/stdout pipe 或 unix socket 跟它通信，WS 复杂度隔离在外部
2. **纯 lua** — vim.uv tcp + 手写 WS 握手/frame 解析，可行但工作量大且容易出 bug

## Companion WS Proxy 实现细节

> 以下基于 companion v0.72.0 源码分析，重点是可搬用的代码和架构。

### 整体架构

```
Browser (React)                    Bun Server (Hono)                   Claude Code CLI
    │                                    │                                    │
    │◄── WS /ws/browser/:sessionId ──►│                                    │
    │    (JSON, 自定义协议)              │◄── WS /ws/cli/:sessionId ──────►│
    │                                    │    (NDJSON, SDK 协议)              │
    │                                    │                                    │
    │  user_message ──────────────────►│  转成 {type:"user",...} ──────────►│
    │                                    │                                    │
    │◄── assistant/stream_event ───────│◄── NDJSON 消息 ───────────────────│
    │                                    │                                    │
    │◄── permission_request ───────────│◄── control_request(can_use_tool) ─│
    │  permission_response ────────────►│  转成 control_response ──────────►│
```

关键点：Browser↔Server 和 Server↔CLI 是**两套不同协议**。Server 做协议翻译，不是纯透传。

### 核心文件和职责

| 文件 | 职责 | 行数 |
|------|------|------|
| `index.ts` | Bun.serve 入口，WS upgrade 路由分发 | ~370 |
| `cli-launcher.ts` | spawn CLI 进程，传 --sdk-url 参数 | ~800 |
| `ws-bridge.ts` | 消息路由核心，CLI↔Browser 桥接 | ~1220 |
| `ws-bridge-types.ts` | Session 数据结构 | ~95 |
| `ws-bridge-controls.ts` | control_request 构造（interrupt/set_model/mcp 等） | ~150 |
| `ws-bridge-browser.ts` | Browser 侧消息处理（subscribe/ack/permission） | ~137 |
| `ws-bridge-replay.ts` | 消息去重、事件序列号、断线重放 | ~60 |
| `session-types.ts` | 完整 TypeScript 类型定义 | ~440 |

### WS Server 启动（index.ts）

```typescript
// Bun 原生 WS server，通过 URL path 区分 CLI/Browser/Terminal
const server = Bun.serve<SocketData>({
  port: 3456,
  fetch(req, server) {
    // CLI 连接：/ws/cli/{sessionId}
    const cliMatch = url.pathname.match(/^\/ws\/cli\/([a-f0-9-]+)$/);
    if (cliMatch) {
      server.upgrade(req, { data: { kind: "cli", sessionId: cliMatch[1] } });
    }
    // Browser 连接：/ws/browser/{sessionId}?token=xxx
    const browserMatch = url.pathname.match(/^\/ws\/browser\/([a-f0-9-]+)$/);
    if (browserMatch) {
      server.upgrade(req, { data: { kind: "browser", sessionId: browserMatch[1] } });
    }
  },
  websocket: {
    open(ws) {
      if (ws.data.kind === "cli") wsBridge.handleCLIOpen(ws, ws.data.sessionId);
      else if (ws.data.kind === "browser") wsBridge.handleBrowserOpen(ws, ws.data.sessionId);
    },
    message(ws, msg) {
      if (ws.data.kind === "cli") wsBridge.handleCLIMessage(ws, msg);
      else if (ws.data.kind === "browser") wsBridge.handleBrowserMessage(ws, msg);
    },
    close(ws) { /* 对应 handleCLIClose / handleBrowserClose */ },
  },
});
```

### CLI Spawn 参数（cli-launcher.ts）

```typescript
// 核心 spawn 逻辑
const sdkUrl = `ws://localhost:${this.port}/ws/cli/${sessionId}`;
const args = [
  "--sdk-url", sdkUrl,
  "--print",
  "--output-format", "stream-json",
  "--input-format", "stream-json",
  "--include-partial-messages",  // 新版需要，开启流式 chunk
  "--verbose",
];
if (options.model) args.push("--model", options.model);
if (options.permissionMode) args.push("--permission-mode", options.permissionMode);
if (options.resumeSessionId) args.push("--resume", options.resumeSessionId);
args.push("-p", "");  // headless 占位

const proc = Bun.spawn([binary, ...args], {
  cwd: info.cwd,
  env: { ...process.env, CLAUDECODE: undefined },
  stdout: "pipe",
  stderr: "pipe",
});
```

环境变量：
- `CLAUDECODE` 必须 unset（否则 CLI 行为异常）
- `CLAUDE_CODE_SESSION_ACCESS_TOKEN` — WS 认证 token（可选）

### WS Bridge 消息路由（ws-bridge.ts）

**CLI → Browser 方向**：

```typescript
// NDJSON 解析
handleCLIMessage(ws, raw) {
  const lines = data.split("\n").filter(l => l.trim());
  for (const line of lines) {
    const msg = JSON.parse(line);
    this.routeCLIMessage(session, msg);
  }
}

// 路由分发
routeCLIMessage(session, msg) {
  switch (msg.type) {
    case "system":     → 更新 session state，广播 session_init/status_change
    case "assistant":  → 存入 messageHistory，广播给所有 browser
    case "result":     → 更新 cost/turns，广播，触发 auto-naming
    case "stream_event": → 直接广播（不存历史）
    case "control_request": → 提取 can_use_tool，存入 pendingPermissions，广播 permission_request
    case "tool_progress":   → 广播
    case "keep_alive":      → 静默消费
  }
}
```

**Browser → CLI 方向**：

```typescript
// Browser 发 user_message → 转成 SDK 协议的 user 消息
handleUserMessage(session, msg) {
  const ndjson = JSON.stringify({
    type: "user",
    message: { role: "user", content: msg.content },
    parent_tool_use_id: null,
    session_id: session.state.session_id || "",
  });
  this.sendToCLI(session, ndjson);
}

// Browser 发 permission_response → 转成 control_response
// (在 ws-bridge-browser.ts handlePermissionResponse)
if (msg.behavior === "allow") {
  sendToCLI(session, JSON.stringify({
    type: "control_response",
    response: {
      subtype: "success",
      request_id: msg.request_id,
      response: { behavior: "allow", updatedInput: msg.updated_input ?? pending.input },
    },
  }));
}
```

**sendToCLI 带消息队列**：

```typescript
sendToCLI(session, ndjson) {
  if (!session.cliSocket) {
    // CLI 还没连上，先排队
    session.pendingMessages.push(ndjson);
    return;
  }
  session.cliSocket.send(ndjson + "\n");  // NDJSON 需要换行分隔
}
```

### Session 数据结构

```typescript
interface Session {
  id: string;                    // launcher 分配的 UUID
  cliSocket: ServerWebSocket | null;  // CLI 的 WS 连接
  browserSockets: Set<ServerWebSocket>;  // 多个 browser 可同时连
  state: SessionState;           // model, cwd, tools, cost, turns 等
  pendingPermissions: Map<string, PermissionRequest>;  // 等待审批的 tool call
  pendingControlRequests: Map<string, PendingControlRequest>;  // 等待 CLI 回复的控制请求
  messageHistory: BrowserIncomingMessage[];  // 完整对话历史（用于 browser 重连回放）
  pendingMessages: string[];     // CLI 未连接时的消息队列
  nextEventSeq: number;          // 事件序列号（用于断线重放）
  eventBuffer: BufferedBrowserEvent[];  // 事件缓冲区（最多 600 条）
}
```

### 多 Session 支持

完全支持。每个 session 独立的 CLI 进程 + 独立的 WS 连接：
- `CliLauncher.sessions: Map<sessionId, SdkSessionInfo>` — 进程管理
- `WsBridge.sessions: Map<sessionId, Session>` — 消息路由
- URL path 里的 sessionId 做路由：`/ws/cli/{sessionId}`, `/ws/browser/{sessionId}`
- 一个 browser 只连一个 session，但一个 session 可以有多个 browser

### 断线重连

- CLI 断开 → `handleCLIClose` → 广播 `cli_disconnected` → browser 重连时触发 `onCLIRelaunchNeeded` → 自动 relaunch（最多 3 次）
- Browser 断开重连 → `handleBrowserOpen` → 发送 `session_init` + `message_history` 回放
- 事件序列号机制：每条广播消息带 `seq`，browser 发 `session_subscribe(last_seq)` 请求补发缺失事件

### 会话恢复

```typescript
// relaunch 时传 --resume 恢复 CLI 内部会话
if (options.resumeSessionId) {
  args.push("--resume", options.resumeSessionId);
}
```

CLI 的 `session_id`（system/init 里报的）和 launcher 的 `sessionId`（UUID）是两个不同的 ID。launcher 存储 `cliSessionId` 用于 --resume。

### 可直接搬的代码

1. **CLI spawn 参数** — 完整的 args 列表和环境变量处理，直接搬
2. **NDJSON 解析** — `data.split("\n").filter(l => l.trim())` + `JSON.parse`
3. **消息路由 switch** — `routeCLIMessage` 的 type 分发逻辑
4. **权限审批协议** — `handlePermissionResponse` 的 control_response 构造
5. **消息队列** — `sendToCLI` 的 pendingMessages 队列模式
6. **user 消息构造** — `handleUserMessage` 的 NDJSON 格式

### 简化成 stdio ↔ WS 纯桥接？

不太行。原因：
1. Browser↔Server 协议和 CLI↔Server 协议不同，需要翻译
2. Session state 管理（model/cwd/tools/cost）在 server 侧维护
3. 权限请求需要 server 侧暂存（pendingPermissions），等 browser 回复后再转发
4. 消息历史和断线重放需要 server 侧缓存

但如果我们的场景是 **nvim 直接控制 CLI**（不经过 browser），可以大幅简化：
- nvim 起 WS server → CLI 连过来
- nvim 直接处理 NDJSON 消息（不需要协议翻译）
- 权限审批在 nvim 侧做（浮动窗口 y/n）
- 不需要 session store / event replay / 多 browser 支持

### 依赖和运行要求

- **运行时**：Bun >= 1.0（用了 `Bun.serve`, `Bun.spawn`, `ServerWebSocket` 等 Bun 专有 API）
- **不能用 Node.js**：大量 Bun 特有 API，移植到 Node 需要替换 WS 库（ws）和进程管理
- **核心依赖**：hono（HTTP 框架）、ws（仅用于 Codex WS proxy 的 Node 子进程）
- **前端**：React + Vite + Tailwind + zustand

## 其他 CLI 的类似机制

### Codex (OpenAI)

有类似能力。启动方式不同，用 `app-server` 子命令：

```bash
codex app-server --listen ws://127.0.0.1:{port}
```

- 协议是 JSON-RPC（不是 NDJSON）
- Companion 里用 `CodexAdapter`（`web/server/codex-adapter.ts`）做协议翻译，把 JSON-RPC 映射成和 Claude 一样的 browser 消息格式
- 也支持 stdio 模式（stdin/stdout 传 JSON-RPC），WS 是新增的
- 支持 `--enable multi_agent` 多 agent 模式

### Gemini CLI

目前没有类似的 sdk-url 或 app-server 模式，没有暴露程序化控制接口。只能走终端模拟。

### 权限控制策略

可以做分级自动审批，不用每个 tool 都弹窗：

- **自动 allow**：Read、Grep、Glob、Bash(只读命令) 等安全 tool
- **弹窗确认**：Write、Edit、Bash(写操作)、危险命令
- **自动 deny**：rm -rf、force push 等高危操作
- 规则可配置，类似 Claude Code 自己的 permission mode
