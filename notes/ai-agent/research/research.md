# AI-to-AI 通信研究报告

基于 codecompanion.nvim、avante.nvim、copilot.lua 三个插件的源码研究。

## 核心发现：ACP 协议

codecompanion 和 avante 都实现了 **ACP (Agent Communication Protocol)**，这是目前 AI coding 工具间通信的事实标准。

### ACP 是什么

- 基于 **JSON-RPC 2.0** 的双向通信协议
- 通过 **stdio**（stdin/stdout）传输
- 支持请求/响应、通知、流式更新
- 支持权限请求和文件系统操作

### 消息格式

每行一条 JSON 消息，换行符分隔：

```
→ {"jsonrpc":"2.0","id":1,"method":"initialize","params":{...}}\n
← {"jsonrpc":"2.0","id":1,"result":{"protocolVersion":1,"agentCapabilities":{...}}}\n
→ {"jsonrpc":"2.0","id":2,"method":"session/new","params":{"cwd":"/path"}}\n
← {"jsonrpc":"2.0","id":2,"result":{"sessionId":"sess-123"}}\n
→ {"jsonrpc":"2.0","id":3,"method":"session/prompt","params":{"sessionId":"sess-123","prompt":[...]}}\n
← {"jsonrpc":"2.0","method":"session/update","params":{"sessionUpdate":"agent_message_chunk","content":{"type":"text","text":"Hello"}}}\n
← {"jsonrpc":"2.0","method":"session/update","params":{"sessionUpdate":"tool_call","toolCallId":"tc-1","kind":"edit",...}}\n
← {"jsonrpc":"2.0","id":99,"method":"session/request_permission","params":{"toolCall":{...},"options":[...]}}\n
→ {"jsonrpc":"2.0","id":99,"result":{"outcome":"selected","optionId":"allow_once"}}\n
← {"jsonrpc":"2.0","id":3,"result":{"stopReason":"end_turn"}}\n
```

### 通信方向

| 方向 | 类型 | 方法 |
|------|------|------|
| Client → Agent | 请求 | `initialize`, `session/new`, `session/prompt`, `session/cancel` |
| Agent → Client | 响应 | 对上述请求的 result |
| Agent → Client | 通知 | `session/update`（流式消息、思考、工具调用状态） |
| Agent → Client | 请求 | `session/request_permission`, `fs/read_text_file`, `fs/write_text_file` |
| Client → Agent | 响应 | 权限决定、文件内容 |

### 生命周期

```
1. initialize        → 握手，交换能力
2. authenticate      → 认证（可选）
3. session/new       → 创建会话
4. session/prompt    → 发送任务
5. session/update *N → 流式接收更新（思考、消息、工具调用）
6. request_permission → 权限确认（双向）
7. prompt 响应       → 任务完成（stopReason: end_turn）
```

---

## 三个插件对比

### codecompanion.nvim — ACP 适配器架构

**最值得借鉴**：它把 ACP 做成了适配器模式，已经支持 9 个外部 agent：

| 适配器 | CLI 命令 |
|--------|---------|
| claude_code | `claude-agent-acp` |
| codex | `codex` |
| gemini_cli | `gemini` |
| goose | `goose` |
| kimi_cli | `kimi` |
| auggie_cli | `auggie` |
| mistral_vibe | `mistral-vibe` |
| opencode | `opencode` |
| cagent | 通用 |

**关键实现**：
- `vim.system()` 启动子进程，stdin/stdout 管道通信
- `LineBuffer` 处理不完整的 JSON 行
- `IdGenerator` 生成请求 ID
- `pending_responses` 表匹配请求和响应
- `vim.wait(10)` 轮询等待响应（超时 20s）
- 权限请求通过 UI 弹窗让用户确认

### avante.nvim — dispatch_agent + agent_loop

**最值得借鉴**：它的 `dispatch_agent` 工具实现了 AI 调 AI 的完整循环：

```
主 Agent
  ↓ dispatch_agent 工具
  ↓ 启动子 agent_loop
  ↓ 子 agent 有自己的工具集（ls, grep, glob, view, attempt_completion）
  ↓ 子 agent 通过 attempt_completion 返回结果
  ↓ 结果作为 tool_result 反馈给主 Agent
主 Agent 继续工作
```

**关键设计**：
- 子 agent 工具集受限（只读，不能写文件/执行命令）
- 子 agent 通过 `attempt_completion` 工具标记"我完成了"
- 主 agent 可以并发启动多个子 agent
- 每个子 agent 是无状态的

### copilot.lua — LSP 通信模型

**值得借鉴**：
- 用 Neovim 原生 LSP 客户端做通信，零额外依赖
- 单进程服务多 buffer，资源高效
- 异步回调模式，不阻塞编辑器
- `$/cancelRequest` 支持取消正在进行的请求

---

## 对你的架构的启示

### 现状 vs ACP

你现在的 agent_api.lua：
```
Claude-1 → send_to_terminal → Claude-2 的 stdin（原始文本）
Claude-1 → get_terminal_output → Claude-2 的 terminal buffer（原始文本）
```

ACP 的方式：
```
Client → stdin → JSON-RPC 消息 → Agent
Agent → stdout → JSON-RPC 消息 → Client
```

**核心区别**：ACP 是结构化的，你的是原始文本。

### 问题：Claude CLI 支持 ACP 吗？

**是的！** codecompanion 的 `claude_code.lua` 适配器用的命令是 `claude-agent-acp`，说明 Claude Code CLI 有一个 ACP 模式。

这意味着你可以：
1. 不用 `spawn_cli` 开 terminal 跑 `claude`
2. 而是用 `vim.system` 启动 `claude-agent-acp` 进程
3. 通过 stdin/stdout 发送 JSON-RPC 消息
4. 结构化地接收响应、处理权限请求

### 但是——人工介入的问题

ACP 模式下，Claude 是一个后台进程，没有 terminal UI。人看不到它在干什么，也没法直接打字介入。

所以你面临一个选择：

| | Terminal 模式（现有） | ACP 模式 |
|---|---|---|
| 通信 | 原始文本，难解析 | 结构化 JSON-RPC |
| 人工介入 | 切 tab 直接打字 | 需要额外 UI |
| 权限确认 | 人在 terminal 按 y/n | 通过 JSON-RPC 弹窗确认 |
| 实时可见 | 看到完整 CLI 输出 | 需要自己渲染 |
| 判断完成 | 轮询/猜测 | stopReason 明确告知 |

### 可能的混合方案

1. **ACP 做通信骨干** — 结构化消息、明确的完成信号、权限处理
2. **nvim buffer 做 UI** — 把 ACP 的流式更新渲染到一个 buffer 里，人能看到
3. **人通过 buffer 介入** — 在 buffer 里写消息，转成 ACP prompt 发给 agent

这就是 codecompanion 和 avante 正在做的事情——它们的 chat buffer 就是 ACP 的 UI 层。

---

## 下一步建议

1. 验证 `claude-agent-acp` 命令是否可用
2. 如果可用，在 agent_api.lua 里加一个 ACP 客户端
3. 用 nvim buffer 渲染 ACP 的流式更新
4. 权限请求通过 nvim 弹窗处理

或者更简单的路径：直接用 codecompanion.nvim 的 ACP 系统，它已经把这些都做好了。
