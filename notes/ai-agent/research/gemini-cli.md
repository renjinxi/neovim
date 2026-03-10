# Gemini CLI 程序化控制研究

> 来源：[google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli) 源码分析

## 结论

Gemini CLI 没有 Claude Code `--sdk-url` 那样的单一 WS 接口，但提供了多个程序化控制方案。
对 nvim 集成最有价值的是 `--acp` 模式（stdin/stdout JSON-RPC），不需要起 WS server。

## 1. `--acp` 模式（最接近 sdk-url）

ACP = Agent Client Protocol，走 stdin/stdout 的 ND-JSON。

```bash
gemini --acp
```

- 协议：JSON-RPC over stdin/stdout（用 `@agentclientprotocol/sdk` v0.12.0）
- 双向通信，支持 tool 确认流程
- 不需要 WS server，直接 pipe
- 源码：`packages/cli/src/acp/acpClient.ts`

```typescript
// acpClient.ts 核心逻辑
const stdout = Writable.toWeb(workingStdout);
const stdin = Readable.toWeb(process.stdin);
const stream = acp.ndJsonStream(stdout, stdin);
const connection = new acp.AgentSideConnection(
  (connection) => new GeminiAgent(config, settings, argv, connection),
  stream,
);
```

## 2. 非交互模式 + stream-json

```bash
echo "prompt" | gemini --prompt - --output-format stream-json
```

- 输出格式：`text` / `json` / `stream-json`
- stream-json 是 SSE 风格，事件类型：INIT, MESSAGE, RESULT, TOOL_CALL 等
- 源码：`packages/cli/src/nonInteractiveCli.ts`
- 单向（只能发一次 prompt），不如 --acp 灵活

## 3. A2A Server（HTTP 服务模式，实验性）

`packages/a2a-server` — Express HTTP server：

```bash
CODER_AGENT_PORT=41242 node dist/src/http/server.js
```

| 端点 | 方法 | 说明 |
|------|------|------|
| `/tasks` | POST | 创建任务，返回 taskId |
| `/executeCommand` | POST | 执行命令，支持 SSE 流式响应 |
| `/listCommands` | GET | 列出可用命令 |
| `/tasks/metadata` | GET | 获取所有任务元数据 |
| `/tasks/:taskId/metadata` | GET | 获取单个任务元数据 |

- Bearer token / Basic auth 认证
- 任务持久化（内存或 GCS）
- 用 `@a2a-js/sdk` v0.3.8

## 4. SDK 包（Node.js 编程接口）

```bash
npm install @google/gemini-cli-sdk
```

```typescript
const agent = new GeminiCliAgent({
  instructions: 'You are a helpful assistant.',
  cwd: '/path/to/project',
  model: 'gemini-2.5-pro',
  tools: [...],
});
const session = agent.session({ sessionId: 'xxx' });
await session.initialize();

for await (const event of session.sendStream(prompt, signal)) {
  // ServerGeminiStreamEvent
}
```

- 完整编程控制
- 自定义 tools/skills
- 会话管理和恢复
- AbortSignal 支持取消

## 5. IDE Companion（MCP 协议）

`packages/vscode-ide-companion` — VSCode 扩展用的 MCP server：

- HTTP server on localhost，`POST /mcp` 端点
- MCP 协议双向通信
- 环境变量：`GEMINI_CLI_IDE_SERVER_PORT`, `GEMINI_CLI_IDE_AUTH_TOKEN`
- 提供 IDE 上下文（打开的文件、选区、diff 管理）

## 6. DevTools（WebSocket 调试）

`packages/devtools` — 开发调试用：

- WebSocket server 端口 25417
- SSE 端点 `/events`
- 网络和 console 日志流
- 消息类型：register, console, network, pong

## CLI 关键参数

| Flag | 说明 |
|------|------|
| `--acp` | ACP 模式（stdin/stdout JSON-RPC） |
| `--prompt` / `-p` | 非交互 headless 模式 |
| `--output-format` / `-o` | text / json / stream-json |
| `--model` / `-m` | 指定模型 |
| `--sandbox` / `-s` | 沙箱模式 |
| `--approval-mode` | default / auto_edit / yolo / plan |
| `--resume` / `-r` | 恢复会话 |
| `--extensions` / `-e` | 扩展 |
| `--raw-output` | 禁用输出清理 |

## 三家 CLI 对比

| | Claude Code | Codex | Gemini CLI |
|---|---|---|---|
| 主要接口 | `--sdk-url` (WS) | `app-server --listen` (WS) | `--acp` (stdin/stdout) |
| 协议 | NDJSON over WS | JSON-RPC over WS/stdio | JSON-RPC over stdio |
| HTTP server | 无 | 无 | A2A Server (实验性) |
| SDK 包 | `@anthropic-ai/claude-agent-sdk` | 内置 | `@google/gemini-cli-sdk` |
| 权限控制 | control_request/response | 类似 | ACP 协议内置 |
| IDE 集成 | VSCode 扩展 | 无 | MCP server |

## nvim 集成启示

Gemini 的 `--acp` 模式对 nvim 最友好：
- 不需要起 WS server
- 直接 `vim.uv.spawn` + pipe stdin/stdout 双向通信
- JSON-RPC 协议成熟，解析简单
- 比 Claude 的 WS 方案实现成本更低

统一多 CLI 控制的架构可以是：
```
nvim
├── Claude:  外挂 WS proxy 进程 ←→ --sdk-url WS
├── Codex:   外挂 WS proxy 进程 ←→ app-server --listen WS
└── Gemini:  直接 vim.uv.spawn  ←→ --acp stdin/stdout
```

每个 CLI 一个 adapter，统一成内部消息格式，上层交互界面（buffer + 弹窗）不感知差异。
