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

- [ ] 读 ACP 协议规范，整理完整消息类型
- [ ] 研究 codecompanion.nvim 的 ACP client 实现
- [ ] 研究 agent-team (nekocode) 的多 agent 编排逻辑
- [ ] 研究 acpx 的 headless client 实现
- [ ] 验证 `gemini --acp` 实际通信流程（抓包/日志）
- [ ] 评估 Claude ACP wrapper 的可行性
- [ ] 原型：nvim 里 spawn gemini --acp，发一条消息，收到回复
