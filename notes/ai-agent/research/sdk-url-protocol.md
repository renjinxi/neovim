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
