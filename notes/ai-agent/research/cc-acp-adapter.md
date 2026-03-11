# claude-agent-acp 研究笔记

> 仓库：https://github.com/zed-industries/claude-agent-acp
> 版本：0.21.0 | 依赖：claude-agent-sdk 0.2.71 + @agentclientprotocol/sdk 0.15.0
> 克隆位置：/tmp/acp-research/claude-agent-acp

## 核心发现

这不是 WS 桥接。它完全不用 `--sdk-url`。

它用的是 `@anthropic-ai/claude-agent-sdk`，这个 SDK 内部 spawn 一个 Claude Code 子进程，通过 stdin/stdout pipe 通信（ProcessTransport）。适配器本身是一个 ACP agent 进程，通过 stdin/stdout 和 ACP client（如 Zed）通信。

```
Zed (ACP Client) ←stdin/stdout NDJSON→ claude-agent-acp ←ProcessTransport→ Claude Code CLI
```

## 启动方式

```bash
# 作为 ACP agent 运行（stdin/stdout 模式）
ANTHROPIC_API_KEY=sk-... claude-agent-acp

# 作为 Claude CLI 运行（透传模式）
claude-agent-acp --cli
```

入口 `src/index.ts`：
- stdout 重定向到 stderr（stdout 专用于 ACP 消息）
- `runAcp()` 创建 `ndJsonStream(stdout, stdin)` + `AgentSideConnection`
- `AgentSideConnection` 接收一个工厂函数 `(client) => new ClaudeAcpAgent(client)`

## 架构：ClaudeAcpAgent

实现 ACP `Agent` 接口，核心方法：

| ACP 方法 | 实现 |
|----------|------|
| `initialize` | 返回 agent 能力声明（支持图片、MCP、session fork/resume/list） |
| `authenticate` | 支持 gateway 认证（自定义 baseUrl + headers）和 terminal 认证（`claude /login`） |
| `newSession` | 创建 Claude Code SDK `query()` 实例 |
| `prompt` | 推消息到 `Pushable<SDKUserMessage>` 队列，循环读 query 输出 |
| `cancel` | `query.interrupt()` |
| `setSessionMode` | 映射到 `query.setPermissionMode()` |
| `setSessionModel` | 映射到 `query.setModel()` |
| `readTextFile` / `writeTextFile` | 透传给 ACP client |

### Session 创建流程（createSession）

```typescript
const q = query({
  prompt: input,           // Pushable<SDKUserMessage> 异步迭代器
  options: {
    cwd: params.cwd,
    systemPrompt: { type: "preset", preset: "claude_code" },
    includePartialMessages: true,
    permissionMode,
    canUseTool: this.canUseTool(sessionId),  // 权限回调
    mcpServers: { ...userMcpServers, ...acpClientMcpServers },
    hooks: { PostToolUse: [...] },
    tools: { type: "preset", preset: "claude_code" },  // 或自定义
    disallowedTools: ["AskUserQuestion"],
    env: { ...process.env, ...gatewayEnv },
    executable: process.execPath,  // node 路径
    // resume / sessionId / extraArgs 等
  },
});
```

关键：`query()` 是 claude-agent-sdk 的核心 API，它内部 spawn Claude Code CLI 子进程。

### 消息循环（prompt 方法）

```
while (true) {
  const { value: message } = await session.query.next();
  switch (message.type) {
    case "system":        → 处理 init/status/compact 等
    case "stream_event":  → 转成 ACP SessionNotification
    case "assistant":     → 转成 ACP 消息（text/thinking/tool_use/tool_result）
    case "user":          → 处理排队的 prompt replay
    case "result":        → 返回 stopReason + usage
  }
}
```

## 消息映射：SDK → ACP

### 文本/思考

| SDK 类型 | ACP sessionUpdate |
|----------|-------------------|
| `text` / `text_delta` | `agent_message_chunk` |
| `thinking` / `thinking_delta` | `agent_thought_chunk` |
| `image` | `agent_message_chunk` (image content) |

### Tool 调用

| SDK 类型 | ACP sessionUpdate |
|----------|-------------------|
| `tool_use` / `server_tool_use` / `mcp_tool_use` | `tool_call`（首次）/ `tool_call_update`（重复） |
| `tool_result` / `mcp_tool_result` / `web_search_tool_result` 等 | `tool_call_update` (status: completed/failed) |
| `TodoWrite` tool_use | `plan` (entries) |

每个 tool_use 会注册一个 PostToolUse hook 回调，用于在 tool 执行完后发送额外的 `tool_call_update`（比如 Edit 的 diff 内容）。

### Tool 信息映射（toolInfoFromToolUse）

每个 Claude 内置 tool 映射到 ACP 的 `ToolInfo`：

| Claude Tool | ACP kind | 特殊处理 |
|-------------|----------|----------|
| Bash | `execute` | 支持 terminal_output 协议 |
| Read | `read` | 显示文件路径和行范围 |
| Write | `edit` | 生成 diff content |
| Edit | `edit` | PostToolUse hook 发 structuredPatch diff |
| Glob | `search` | — |
| Grep | `search` | — |
| Agent/Task | `think` | — |
| WebFetch | `fetch` | — |
| WebSearch | `fetch` | — |
| TodoWrite | `think` | 转成 plan entries |
| MCP tools | `other` | 透传 |

## 权限处理（canUseTool）

Claude SDK 的 `canUseTool` 回调 → 调用 ACP client 的 `requestPermission`：

```typescript
canUseTool: async (toolName, toolInput, { signal, suggestions, toolUseID }) => {
  // bypassPermissions 模式直接 allow
  if (session.permissionMode === "bypassPermissions") {
    return { behavior: "allow", updatedPermissions: [...] };
  }

  // 向 ACP client 请求权限
  const response = await this.client.requestPermission({
    options: [
      { kind: "allow_always", name: "Always Allow", optionId: "allow_always" },
      { kind: "allow_once", name: "Allow", optionId: "allow" },
      { kind: "reject_once", name: "Reject", optionId: "reject" },
    ],
    sessionId,
    toolCall: { toolCallId, rawInput, ...toolInfo },
  });

  // 返回 allow/deny 给 Claude SDK
}
```

ExitPlanMode 有特殊处理：选项是 "Yes, and auto-accept edits" / "Yes, and manually approve edits" / "No, keep planning"。

## MCP Server 注册

ACP client 在 `newSession` 时传入 `mcpServers` 数组，支持两种类型：

```typescript
// HTTP/SSE 类型
{ name: "server1", type: "sse", url: "http://...", headers: [...] }

// stdio 类型
{ name: "server2", command: "npx", args: ["-y", "some-mcp-server"], env: [...] }
```

这些会合并到 Claude SDK 的 `options.mcpServers` 中，Claude Code 内部会连接这些 MCP server 并注册其 tools。

同时，`_meta.claudeCode.options` 可以传入额外的 `mcpServers`，两者会合并：

```typescript
mcpServers: { ...(userProvidedOptions?.mcpServers || {}), ...mcpServers },
```

所以：**支持给 agent 注册自定义 MCP tool**，通过 ACP 的 mcpServers 参数或 _meta 扩展。

## 自定义 Options 透传

通过 `_meta.claudeCode.options` 可以传入大量 Claude SDK 选项：

```typescript
type NewSessionMeta = {
  claudeCode?: {
    options?: Options;  // claude-agent-sdk 的完整 Options
  };
};
```

被 ACP 覆盖的字段：cwd, includePartialMessages, permissionMode, canUseTool, executable
被合并的字段：hooks, mcpServers, disallowedTools
透传的字段：systemPrompt, env, tools, maxThinkingTokens, resume, abortController 等

## Settings 管理

`SettingsManager` 读取 4 层配置（优先级递增）：
1. `~/.claude/settings.json`（用户）
2. `<cwd>/.claude/settings.json`（项目）
3. `<cwd>/.claude/settings.local.json`（本地）
4. 平台 managed-settings.json（企业）

支持 file watcher 自动重载。影响 permissionMode 和 model 选择。

## 依赖和运行要求

- Node.js（或 Bun 单文件构建）
- `@anthropic-ai/claude-agent-sdk` 0.2.71 — 核心，spawn Claude Code CLI
- `@agentclientprotocol/sdk` 0.15.0 — ACP 协议实现
- `@anthropic-ai/claude-code` 2.1.71（devDep）— 提供 tool input 类型
- Claude Code CLI 必须已安装（SDK 会找到并 spawn 它）
- ANTHROPIC_API_KEY 或 gateway 认证

## 对我们的价值

### 直接可用

1. **不需要 WS**：claude-agent-sdk 的 `query()` API 直接 spawn CLI 子进程，stdin/stdout pipe 通信。这比我们之前研究的 `--sdk-url` WS 方案简单得多。

2. **ACP 是正确的抽象层**：这个适配器证明了 ACP stdin/stdout NDJSON 可以完美包装 Claude Code。Gemini CLI 原生支持 ACP，所以一个 ACP client 就能统一控制两者。

3. **MCP 透传**：ACP client 可以在 newSession 时注册 MCP server，Claude Code 会自动连接。这意味着 nvim 可以把自己的能力（buffer 操作、文件系统等）暴露为 MCP server，agent 就能用。

### 两条路线

**路线 A：直接用这个适配器**
- `npm install -g @zed-industries/claude-agent-acp`
- nvim spawn 它，通过 ACP stdin/stdout 通信
- 优点：成熟、Zed 在维护、处理了大量边界情况
- 缺点：多一层进程（nvim → adapter → claude cli），Node.js 依赖

**路线 B：nvim 直接用 claude-agent-sdk**
- 写一个极简 Node 脚本，用 `query()` API
- nvim 通过 stdin/stdout pipe 和这个脚本通信（自定义协议或 ACP）
- 优点：更轻量，可以精确控制
- 缺点：要自己处理消息映射

**路线 C：nvim ACP client + 多 agent**
- nvim 实现通用 ACP client
- Claude 用这个适配器，Gemini 用 `gemini --acp`
- 统一的消息格式、权限模型、UI
- 这是最终目标

### 关键 API 参考

```typescript
// claude-agent-sdk 核心 API
import { query, Query, Options } from "@anthropic-ai/claude-agent-sdk";

const q = query({
  prompt: asyncIterable,  // 用户消息流
  options: {
    cwd: "/path/to/project",
    permissionMode: "default",
    canUseTool: async (toolName, toolInput, opts) => ({ behavior: "allow" }),
    mcpServers: { myServer: { type: "stdio", command: "...", args: [...] } },
    hooks: { PostToolUse: [...] },
  },
});

// 读取消息
for await (const message of q) {
  // message.type: system | assistant | user | stream_event | result | ...
}

// 控制
await q.interrupt();
await q.setModel("claude-sonnet-4-5");
await q.setPermissionMode("bypassPermissions");
```

### 更新 acp-plan.md

之前写的 "Claude Code 没有原生 ACP — 需要 wrapper" 现在有了明确答案：
- Zed 官方维护的 wrapper 已经成熟（v0.21.0，20+ 个版本迭代）
- 不是 WS 桥接，是基于 claude-agent-sdk 的进程级集成
- npm 一装就能用，也有预编译单文件二进制
