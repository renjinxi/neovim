# ACP (Agent Client Protocol) 统一对接方案

## 结论

ACP 是目前最有潜力的统一层。Gemini CLI 原生支持，Copilot CLI 已支持，Claude Code 通过 codecompanion 适配。
stdin/stdout JSON-RPC，不需要 WS server，nvim 里 `vim.uv.spawn` + pipe 就能双向通信。

## ACP 协议概要

- 由 Zed 发起的开放协议，定位是 "AI coding agent 的 LSP"
- JSON-RPC 2.0 over stdin/stdout（ND-JSON 格式）
- 双向：client（编辑器）发请求，agent（CLI）发通知/请求
- 官网：https://agentclientprotocol.com
- SDK：`@agentclientprotocol/sdk`

## 各 CLI 支持情况

| CLI | ACP 支持 | 启动方式 | 备注 |
|-----|----------|----------|------|
| Gemini CLI | ✅ 原生 | `gemini --acp` | 用 `@agentclientprotocol/sdk` v0.12.0 |
| Copilot CLI | ✅ 原生 | ACP server 模式 | GitHub 官方支持 |
| Claude Code | 🔶 适配 | codecompanion 包装 | 非原生，通过 wrapper 转换 |
| Codex | ❌ 无 | — | 只有 app-server (JSON-RPC/WS) |

## 已有 nvim 生态

### codecompanion.nvim
- 已实现 ACP client，适配了 9+ 个 CLI agent
- 源码值得研究：它怎么做 ACP 握手、消息路由、UI 渲染
- 关键问题：它的 ACP 实现是否可以独立抽出来用

### 待研究的仓库
- [zed-industries/agent-client-protocol](https://github.com/zed-industries/agent-client-protocol) — 协议规范 + SDK
- [zed-industries/zed](https://github.com/zed-industries/zed) — Zed 编辑器源码，ACP 的发起者和第一个 client 实现，重点研究其 ACP client 怎么做握手、消息路由、权限审批、UI 渲染
- [openclaw/acpx](https://github.com/openclaw/acpx) — Headless CLI client for ACP sessions
- [nekocode/agent-team](https://github.com/nekoobsidian-agent-clientcode/agent-team) — 多 agent CLI 编排器，通过 ACP 管理 20+ agent
- [RAIT-09/obsidian-agent-client](https://github.com/RAIT-09/obsidian-agent-client) — Obsidian 里通过 ACP 对接 Claude/Codex/Gemini
- [nuskey8/UnityAgentClient](https://github.com/nuskey8/UnityAgentClient) — Unity 编辑器通过 ACP 对接多 CLI
- [anomalyco/opencode](https://github.com/anomalyco/opencode) — 终端 AI 编码工具，研究其架构和多 agent 通信方式

## nvim 集成架构（草案）

```
nvim (ACP Client)
│
├── lua/core/acp_client.lua        ← ACP JSON-RPC 协议层
│   ├── spawn(cmd, args)           ← vim.uv.spawn + pipe
│   ├── send_request(method, params)
│   ├── on_notification(method, cb)
│   └── on_request(method, handler)  ← agent 发来的权限请求等
│
├── lua/core/acp_agents.lua        ← 多 agent 管理
│   ├── start_agent(type, opts)    ← type: gemini/claude/copilot
│   ├── send_message(agent_id, content)
│   ├── list_agents()
│   └── stop_agent(agent_id)
│
└── UI 层
    ├── chat buffer                ← assistant 输出渲染
    ├── input prompt               ← 用户消息输入
    └── permission popup           ← tool 审批弹窗
```

### 各 CLI 的 spawn 命令

```lua
local agents = {
  gemini = { cmd = "gemini", args = { "--acp" } },
  copilot = { cmd = "copilot-cli", args = { "--acp" } },  -- 待确认具体参数
  claude = { cmd = "claude", args = { "--sdk-url", "..." } },  -- 需要 WS proxy 或 ACP wrapper
  codex = { cmd = "codex", args = { "app-server" } },  -- JSON-RPC stdio
}
```

### 核心问题

1. **Claude Code 没有原生 ACP** — 需要 wrapper 或等官方支持
   - 方案 A：用 codecompanion 的 adapter 逻辑
   - 方案 B：写一个小 node 脚本做 sdk-url WS → ACP stdio 桥接
   - 方案 C：等 Anthropic 跟进 ACP（Zed 在推动）

2. **ACP 协议的权限模型** — 需要研究 ACP 里 tool approval 的具体消息格式
   - Gemini 的 `--approval-mode` 和 ACP 权限请求的关系
   - 和 Claude 的 `control_request/response` 能否统一

3. **人可介入问题** — ACP 是后台进程，没有 terminal
   - 需要自建 chat UI（nvim buffer）
   - 但 nvim buffer 渲染 + input 框 + 权限弹窗 = 完整交互界面
   - 比 terminal 模式更可控，只是不是"原生 CLI 体验"

## TODO

- [x] 读 ACP 协议规范，整理完整消息类型 → 见下方详细研究
- [ ] 研究 codecompanion.nvim 的 ACP client 实现
- [ ] 研究 agent-team (nekocode) 的多 agent 编排逻辑
- [ ] 研究 acpx 的 headless client 实现
- [ ] 验证 `gemini --acp` 实际通信流程（抓包/日志）
- [ ] 评估 Claude ACP wrapper 的可行性
- [ ] 原型：nvim 里 spawn gemini --acp，发一条消息，收到回复

---

# ACP 协议规范详细研究（2026-03-10）

源码：https://github.com/zed-industries/agent-client-protocol
协议版本：`protocolVersion: 1`（整数，只在 breaking change 时递增）
传输层：JSON-RPC 2.0 over stdio（换行分隔，不能内嵌换行）

## 一、完整消息类型清单

### Agent 端方法（Client → Agent 的请求）

| 方法 | 类型 | 必须实现 | 说明 |
|------|------|----------|------|
| `initialize` | request | 必须 | 协商版本和能力 |
| `authenticate` | request | 可选 | 认证（agent 要求时） |
| `session/new` | request | 必须 | 创建新会话 |
| `session/prompt` | request | 必须 | 发送用户消息 |
| `session/cancel` | notification | 必须 | 取消当前 prompt turn |
| `session/load` | request | 可选 | 恢复已有会话（需 `loadSession` 能力） |
| `session/list` | request | 可选 | 列出已有会话（需 `sessionCapabilities.list`） |
| `session/set_mode` | request | 可选 | 切换 agent 模式（将被 config_option 取代） |
| `session/set_config_option` | request | 可选 | 设置会话配置项 |

unstable（feature flag 控制，尚未正式进入 spec）：
- `session/resume` — 恢复会话但不回放历史
- `session/fork` — 分叉会话
- `session/close` — 关闭会话
- `session/set_model` — 切换模型
- `$/cancel_request` — 取消特定请求

### Client 端方法（Agent → Client 的请求）

| 方法 | 类型 | 必须实现 | 说明 |
|------|------|----------|------|
| `session/request_permission` | request | 必须 | 请求用户授权 tool 执行 |
| `session/update` | notification | 必须 | 流式推送会话更新 |
| `fs/read_text_file` | request | 可选 | 读文件（需 `fs.readTextFile`） |
| `fs/write_text_file` | request | 可选 | 写文件（需 `fs.writeTextFile`） |
| `terminal/create` | request | 可选 | 创建终端执行命令（需 `terminal`） |
| `terminal/output` | request | 可选 | 获取终端输出 |
| `terminal/wait_for_exit` | request | 可选 | 等待命令完成 |
| `terminal/kill` | request | 可选 | 杀死命令 |
| `terminal/release` | request | 可选 | 释放终端资源 |

### session/update 的 sessionUpdate 类型

这是最核心的通知，agent 通过它推送所有实时内容：

| sessionUpdate 值 | 说明 |
|-------------------|------|
| `agent_message_chunk` | agent 文本输出（流式） |
| `user_message_chunk` | 用户消息回放（session/load 时） |
| `thought_message_chunk` | agent 思考过程 |
| `tool_call` | 新建 tool call |
| `tool_call_update` | 更新 tool call 状态/内容 |
| `plan` | 执行计划（含 entries 列表） |
| `available_commands_update` | 可用 slash 命令列表 |
| `current_mode_update` | agent 主动切换模式 |
| `config_option_update` | agent 主动更新配置项 |
| `session_info_update` | 更新会话元数据（标题等） |

## 二、Tool Registration 机制

**ACP 本身没有 tool registration API。** Agent 自己管理 tool，client 无法直接注册自定义 tool。

但有两种方式让 client 给 agent 提供 tool：

### 方式 1：MCP Server 注入（当前可用）

`session/new` 时传入 `mcpServers` 列表，agent 会连接这些 MCP server 并把它们的 tool 暴露给 LLM：

```json
{
  "method": "session/new",
  "params": {
    "cwd": "/path/to/project",
    "mcpServers": [
      {
        "name": "my-custom-tools",
        "command": "/path/to/mcp-server",
        "args": ["--stdio"],
        "env": [{"name": "KEY", "value": "val"}]
      }
    ]
  }
}
```

**这是目前给 agent 注册自定义 tool（如 bus_post）的唯一标准方式。**

client 需要自己跑一个 MCP server 进程，agent 通过 stdio 连接它。
架构文档明确说："Clients MAY use this ability to provide tools directly to the underlying language model by including their own MCP server."

支持的 MCP 传输：
- stdio（所有 agent 必须支持）
- HTTP（可选，需 `mcpCapabilities.http`）
- SSE（可选，已被 MCP 废弃）

### 方式 2：MCP-over-ACP（RFD 阶段，未正式进入 spec）

提案中的 `"transport": "acp"` 类型，让 MCP 消息直接走 ACP 通道，不需要额外进程：

```json
{
  "mcpServers": [{
    "transport": "acp",
    "name": "nvim-tools",
    "id": "550e8400-..."
  }]
}
```

agent 通过 `mcp/connect` → `mcp/message` → `mcp/disconnect` 和 client 交互。
需要 agent 声明 `mcpCapabilities.acp: true`。

**对我们的意义**：如果这个 RFD 通过，nvim 可以直接在 ACP 连接上提供 MCP tool，不需要 spawn 额外进程。但目前还不能用。

### 对 bus_post 的实现方案

当前最可行：nvim spawn 一个轻量 MCP server（可以是 node/python 脚本），在 `session/new` 时注入。这个 MCP server 暴露 `bus_post` tool，内部通过 RPC 或 socket 和 nvim 通信。

## 三、消息发送和接收的完整流程

### Prompt Turn 生命周期

```
Client                          Agent
  │                               │
  │── session/prompt ────────────>│  1. 发送用户消息
  │                               │  2. Agent 处理（调 LLM）
  │<── session/update (plan) ─────│  3. 可选：执行计划
  │<── session/update (agent_msg) │  4. 流式文本输出
  │<── session/update (tool_call) │  5. 报告 tool call（pending）
  │                               │
  │<── request_permission ────────│  6. 可选：请求权限
  │── permission response ───────>│  7. 用户授权/拒绝
  │                               │
  │<── session/update (tool_call) │  8. tool 状态 → in_progress
  │<── fs/read_text_file ─────────│  9. 可选：agent 读文件
  │── file content ──────────────>│
  │<── terminal/create ───────────│  10. 可选：agent 执行命令
  │── terminal_id ───────────────>│
  │<── session/update (tool_call) │  11. tool 状态 → completed
  │                               │
  │  （循环直到 LLM 不再请求 tool）
  │                               │
  │<── session/prompt response ───│  12. 结束，返回 stopReason
```

### StopReason 枚举

- `end_turn` — 正常结束
- `max_tokens` — token 上限
- `max_turn_requests` — 单 turn 内 LLM 请求次数上限
- `refusal` — agent 拒绝继续
- `cancelled` — 用户取消

### Tool Call 状态机

`pending` → `in_progress` → `completed` | `failed`

Tool Call 内容类型：
- `content` — 普通文本/图片
- `diff` — 文件修改（oldText/newText）
- `terminal` — 终端输出引用

Tool Kind：`read` | `edit` | `delete` | `move` | `search` | `execute` | `think` | `fetch` | `other`

## 四、Session 管理

### 创建

```json
// Client → Agent
{ "method": "session/new", "params": { "cwd": "/abs/path", "mcpServers": [...] } }
// Agent → Client
{ "result": { "sessionId": "sess_xxx", "modes": {...}, "configOptions": [...] } }
```

### 恢复（需 loadSession 能力）

```json
{ "method": "session/load", "params": { "sessionId": "sess_xxx", "cwd": "...", "mcpServers": [...] } }
```

Agent 通过 `session/update` 回放完整历史（user_message_chunk + agent_message_chunk + tool_call 等），全部发完后才返回 response。

### 列表（需 sessionCapabilities.list）

```json
{ "method": "session/list", "params": { "cwd": "/filter/path", "cursor": "..." } }
// 返回 sessions 数组 + nextCursor 分页
```

### Session 配置

两套 API（configOptions 是新的，modes 是旧的将被废弃）：

ConfigOption 结构：
```json
{
  "id": "mode",
  "name": "Session Mode",
  "category": "mode",        // mode | model | thought_level
  "type": "select",          // 目前只有 select
  "currentValue": "ask",
  "options": [{ "value": "ask", "name": "Ask" }, ...]
}
```

## 五、权限/Approval 机制

Agent 通过 `session/request_permission` 请求用户授权：

```json
{
  "method": "session/request_permission",
  "params": {
    "sessionId": "sess_xxx",
    "toolCall": { "toolCallId": "call_001", "title": "Running npm test", ... },
    "options": [
      { "optionId": "allow-once", "name": "Allow once", "kind": "allow_once" },
      { "optionId": "allow-always", "name": "Allow always", "kind": "allow_always" },
      { "optionId": "reject-once", "name": "Reject", "kind": "reject_once" },
      { "optionId": "reject-always", "name": "Never allow", "kind": "reject_always" }
    ]
  }
}
```

Client 回复：
```json
{ "result": { "outcome": { "outcome": "selected", "optionId": "allow-once" } } }
// 或取消：
{ "result": { "outcome": { "outcome": "cancelled" } } }
```

**Client 可以自动审批**：spec 明确说 "Clients MAY automatically allow or reject permission requests according to the user settings."

**取消时必须回复 cancelled**：如果 prompt turn 被 cancel，所有 pending 的 permission request 必须回复 cancelled。

## 六、Agent 能力声明（Capabilities）

### Client Capabilities（client 告诉 agent 自己支持什么）

```json
{
  "clientCapabilities": {
    "fs": {
      "readTextFile": true,   // 支持 fs/read_text_file
      "writeTextFile": true   // 支持 fs/write_text_file
    },
    "terminal": true          // 支持所有 terminal/* 方法
  }
}
```

### Agent Capabilities（agent 告诉 client 自己支持什么）

```json
{
  "agentCapabilities": {
    "loadSession": true,                    // 支持 session/load
    "promptCapabilities": {
      "image": true,                        // prompt 可含图片
      "audio": true,                        // prompt 可含音频
      "embeddedContext": true               // prompt 可含嵌入资源
    },
    "mcpCapabilities": {
      "http": true,                         // 支持 HTTP MCP 传输
      "sse": true                           // 支持 SSE MCP 传输（已废弃）
    },
    "sessionCapabilities": {
      "list": {}                            // 支持 session/list
    }
  }
}
```

所有能力都是可选的，未声明 = 不支持。新增能力不算 breaking change。

## 七、扩展性机制

### _meta 字段

所有类型都有 `_meta: { [key: string]: unknown }`，可附加自定义数据。
保留 key：`traceparent`、`tracestate`、`baggage`（W3C trace context）。

### 自定义方法

方法名以 `_` 开头的是扩展方法，如 `_zed.dev/workspace/buffers`。
不认识的自定义请求返回 `-32601 Method not found`。
不认识的自定义通知直接忽略。

### 自定义能力

在 capabilities 的 `_meta` 里声明：
```json
{
  "agentCapabilities": {
    "_meta": { "zed.dev": { "workspace": true } }
  }
}
```

## 八、Content 类型

和 MCP 的 ContentBlock 完全一致：

| 类型 | 说明 | prompt 中需要的能力 |
|------|------|---------------------|
| `text` | 纯文本 | 基线，必须支持 |
| `resource_link` | 资源引用（URI） | 基线，必须支持 |
| `image` | base64 图片 | `promptCapabilities.image` |
| `audio` | base64 音频 | `promptCapabilities.audio` |
| `resource` | 嵌入资源（含内容） | `promptCapabilities.embeddedContext` |

## 九、Proxy/Agent Extension（RFD 阶段）

重要的未来方向：ACP Proxy Chain。

Proxy 坐在 client 和 agent 之间，可以：
- 拦截/修改 prompt（注入上下文）
- 提供 MCP tool（通过 MCP-over-ACP）
- 过滤/转换 response
- 协调多 agent

架构：Client → Conductor → Proxy1 → Proxy2 → ... → Agent

Proxy 通过 `proxy/initialize`（而非 `initialize`）初始化，知道自己有 successor。
消息通过 `proxy/successor` 转发。

**对我们的意义**：如果我们想做"nvim 作为中间层增强 agent"，proxy 是标准化的方式。但目前还是 RFD 阶段。

## 十、对 nvim 实现的关键结论

### 必须实现的 Client 端

1. **JSON-RPC 2.0 双向通信**：spawn 进程 + stdin/stdout pipe
2. **initialize 握手**：声明 clientCapabilities，获取 agentCapabilities
3. **session/new**：传 cwd + mcpServers
4. **session/prompt**：发送用户消息（ContentBlock 数组）
5. **session/update 处理**：解析所有 sessionUpdate 类型，渲染到 UI
6. **session/request_permission 响应**：弹窗让用户选择，或自动审批
7. **session/cancel**：用户中断时发送

### 可选但推荐实现的

1. **fs/read_text_file + fs/write_text_file**：让 agent 能读写 nvim buffer 内容（含未保存修改）
2. **terminal/***：让 agent 能在 nvim 里执行命令
3. **session/load + session/list**：会话持久化和恢复

### 自定义 tool 注入方案

短期：spawn 一个 MCP server 进程，在 session/new 时注入
中期：等 MCP-over-ACP 落地，直接在 ACP 通道上提供 tool
长期：考虑 proxy chain 架构

### 协议版本

当前 `protocolVersion: 1`，v2 目前只有一个提案（clientInfo/agentInfo 变为必填）。协议很稳定。
