# acpx 研究笔记

仓库：https://github.com/openclaw/acpx
定位：Headless CLI client for ACP sessions，用 TypeScript 写的纯 CLI，不依赖任何 UI。
依赖：`@agentclientprotocol/sdk ^0.15.0`，`commander`，Node >= 22.12

## 核心架构

```
CLI command → AcpClient → ndjson/stdio → ACP adapter → coding agent
```

不做 PTY scraping，全程结构化 JSON-RPC 消息。

### 关键文件

- `src/client.ts` — ACP 传输层，spawn adapter 子进程，建立 `ClientSideConnection`
- `src/session-runtime.ts` — 会话生命周期、队列所有权、prompt 执行
- `src/agent-registry.ts` — 内置 agent 注册表
- `src/permissions.ts` — tool approval 策略
- `src/session-persistence/repository.ts` — 会话持久化（`~/.acpx/sessions/*.json`）
- `src/queue-ipc.ts` + `src/queue-ipc-server.ts` — 本地 IPC 队列（Unix socket）

## ACP 协议实现细节

### 握手流程

```
1. spawn adapter 子进程（stdin/stdout pipe）
2. ndJsonStream 包装成双向流
3. ClientSideConnection 建立连接
4. initialize({ protocolVersion, clientCapabilities, clientInfo })
   - clientCapabilities: { fs: { readTextFile, writeTextFile }, terminal: true }
   - clientInfo: { name: "acpx", version: "0.1.0" }
5. 可选：authenticate（如果 adapter 要求）
6. newSession({ cwd, mcpServers }) 或 loadSession({ sessionId, cwd, mcpServers })
7. prompt({ sessionId, prompt: ContentBlock[] })
```

### 消息类型

ACP 是标准 JSON-RPC 2.0，三种消息：

- **Request**: `{ jsonrpc: "2.0", id, method, params }`
- **Response**: `{ jsonrpc: "2.0", id, result }` 或 `{ jsonrpc: "2.0", id, error }`
- **Notification**: `{ jsonrpc: "2.0", method, params }`（无 id）

关键 method：

| 方向 | Method | 说明 |
|------|--------|------|
| client→agent | `initialize` | 握手 |
| client→agent | `session/new` | 创建会话 |
| client→agent | `session/load` | 恢复会话 |
| client→agent | `session/prompt` | 发送 prompt |
| client→agent | `session/cancel` | 取消当前 prompt |
| client→agent | `session/set_mode` | 切换模式（plan/code 等） |
| client→agent | `session/set_config_option` | 设置配置 |
| agent→client | `session/update` | 流式输出（thinking/tool_call/text/done） |
| agent→client | `session/request_permission` | 请求 tool 审批 |
| agent→client | `fs/read_text_file` | 读文件 |
| agent→client | `fs/write_text_file` | 写文件 |
| agent→client | `terminal/create` | 创建终端 |
| agent→client | `terminal/output` | 获取终端输出 |
| agent→client | `terminal/wait_for_exit` | 等待终端退出 |
| agent→client | `terminal/kill` | 杀终端 |
| agent→client | `terminal/release` | 释放终端 |
| agent→client | `authenticate` | 认证 |

### Tool Approval 机制

Permission request 结构：
```typescript
{
  toolCall: { title, kind?, _meta?, rawInput? },
  options: [{ optionId, name, kind: "allow_once"|"allow_always"|"reject_once"|"reject_always" }]
}
```

三种策略：
- `approve-all`：自动选 allow option
- `approve-reads`：read/search 自动批准，其他交互式询问
- `deny-all`：自动 reject

Response 格式：
```typescript
{ outcome: { outcome: "selected", optionId } }  // 选了某个选项
{ outcome: { outcome: "cancelled" } }            // 取消
```

tool kind 推断：从 `toolCall.kind` 或 title 关键词推断（read/search/edit/execute/fetch 等）。

### session/update 通知内容

`sessionUpdate` 字段值：
- `agent_message_chunk` — 文本/thinking 流式块
- `tool_call` — tool 调用开始/完成
- `tool_call_update` — tool 调用状态更新
- `available_commands_update` — 可用命令变更
- `plan` / `agent_thought_chunk` / `user_message_chunk`

### Prompt 输入格式

`ContentBlock[]`，支持：
- `{ type: "text", text }` — 纯文本
- `{ type: "image", mimeType, data }` — 图片
- `{ type: "resource_link", uri, title?, name? }` — 资源链接
- `{ type: "resource", resource: { uri, text? } }` — 内联资源

## 会话生命周期

### 创建

```
createSession() → client.start() → client.createSession(cwd)
  → 写 SessionRecord 到 ~/.acpx/sessions/<id>.json
```

SessionRecord 核心字段：
- `acpxRecordId` — 本地稳定 ID
- `acpSessionId` — ACP 线上 session ID（可能因 reconnect 变化）
- `agentSessionId` — agent 内部 session ID（可选，从 `_meta.agentSessionId` 提取）
- `agentCommand`, `cwd`, `name`
- `pid` — adapter 进程 PID
- `messages[]` — 对话历史
- `closed`, `closedAt` — 软关闭状态

### 恢复

查找逻辑：`findSessionByDirectoryWalk`
1. 从当前 cwd 向上走到 git root
2. 每层匹配 `(agentCommand, dir, name?)`
3. 找到后 `loadSession(sessionId, cwd, mcpServers)`
4. load 失败（not found 等）→ fallback 到 `newSession`

### 队列所有权模型

每个 session 同时只有一个 queue owner 进程：
- owner 通过 `~/.acpx/queues/*.lock` 获取 lease
- 其他 acpx 进程通过 Unix socket IPC 提交 prompt 到 owner
- owner 串行执行 prompt（一次一个 ACP turn）
- 空闲 TTL 到期后 owner 退出（默认 300s）
- 支持 `--no-wait` 模式：提交后立即返回

IPC 消息类型：
- `submit_prompt` — 提交 prompt
- `cancel_prompt` — 取消
- `set_mode` — 切换模式
- `set_config_option` — 设置配置

### 销毁（软关闭）

```
closeSession() → terminateQueueOwner → kill adapter PID → 标记 closed=true
```
不删文件，保留在磁盘上。

## 支持的 Agent

```typescript
AGENT_REGISTRY = {
  pi:       "npx pi-acp@^0.0.22",
  openclaw: "openclaw acp",
  codex:    "npx @zed-industries/codex-acp@^0.9.5",
  claude:   "npx -y @zed-industries/claude-agent-acp@^0.21.0",
  gemini:   "gemini --experimental-acp",
  cursor:   "cursor-agent acp",
  copilot:  "copilot --acp --stdio",
  kimi:     "kimi acp",
  opencode: "npx -y opencode-ai acp",
  kiro:     "kiro-cli acp",
  kilocode: "npx -y @kilocode/cli acp",
  qwen:     "qwen --acp",
}
```

默认 agent：`codex`。支持通过 config 自定义 agent command。

特殊处理：
- Gemini：启动超时检测（15s），版本检测
- Claude：session 创建超时检测（60s）
- Copilot：`--help` 检测是否支持 `--acp`

## 我们能直接用的部分

### 1. ACP 协议流程已验证

acpx 验证了完整的 ACP 协议流程：initialize → newSession/loadSession → prompt → stream updates。
我们在 nvim 里用 `vim.uv.spawn` + pipe 实现同样的 ndjson 双向通信即可。

### 2. ClientSideConnection 的回调模式

agent 会主动调用 client 的方法（fs/read, fs/write, terminal/*, requestPermission）。
我们需要在 nvim 端实现这些 handler：
- `requestPermission` → nvim 弹窗让用户选择
- `fs/readTextFile` → `vim.fn.readfile`
- `fs/writeTextFile` → `vim.fn.writefile`（需要权限确认）
- `terminal/*` → nvim terminal API
- `sessionUpdate` → 流式渲染到 buffer

### 3. 会话恢复机制

`loadSession` 可以恢复之前的对话上下文，不需要重新发送历史。
如果 agent 不支持 loadSession（`agentCapabilities.loadSession`），fallback 到 newSession。

### 4. Permission 策略可复用

三级策略 + tool kind 推断逻辑可以直接搬到 nvim 端。
`approve-reads` 是最实用的默认值：读操作自动批准，写/执行需要确认。

### 5. Agent 注册表

所有 ACP adapter 的启动命令已经整理好了，直接用。
注意 claude 需要 `@zed-industries/claude-agent-acp` 适配器，不是直接调 claude CLI。

### 6. 队列模型的启发

acpx 的 queue owner 模型解决了"多个调用者共享一个 agent 进程"的问题。
我们在 nvim 里可能不需要这么复杂，但"一个 session 一个 agent 进程"的模型值得参考。

### 7. 流式输出处理

`session/update` 的 `agent_message_chunk` 是增量文本，直接 append 到 buffer。
`tool_call` / `tool_call_update` 可以渲染为状态行。

### 8. 错误恢复

- adapter 进程挂了 → 重新 spawn + loadSession
- loadSession 失败 → fallback newSession
- prompt 超时 → cancel + 保存当前状态
这套恢复逻辑在 nvim 端同样需要。
