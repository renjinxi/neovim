# 落地方案：agent_api + mcp_agent_mail

## 状态：待验证

## 核心思路

不需要新写什么东西。现有的 agent_api.lua 负责进程管理，mcp_agent_mail 负责通信。

```
┌─────────────────────────────────────────────────────┐
│                     nvim                             │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │ 主 Claude │  │ 子 Claude│  │ 子 Gemini│  ← 各自   │
│  │ terminal │  │ terminal │  │ terminal │    terminal│
│  └────┬─────┘  └────┬─────┘  └────┬─────┘           │
│       │ MCP         │ MCP         │ MCP              │
│       └─────────────┼─────────────┘                  │
│                     ↓                                │
│          ┌─────────────────────┐                     │
│          │  mcp_agent_mail     │                     │
│          │  HTTP :8765         │                     │
│          │  SQLite + Git 归档   │                     │
│          └─────────────────────┘                     │
│                                                      │
│  人：切 tab 到任意 terminal 直接打字                    │
└─────────────────────────────────────────────────────┘
```

## 各层职责

| 层 | 工具 | 职责 |
|---|---|---|
| 进程管理 | agent_api.lua | spawn_cli 起子 AI，list_terminals 查状态 |
| 通信 | mcp_agent_mail | send_message / fetch_inbox / reply_message |
| 文件冲突 | mcp_agent_mail | file_reservation 防多 AI 编辑同一文件 |
| 人工介入 | nvim terminal | 切 tab 直接打字，和正常用 :AI 一样 |

## 典型流程

```
1. 你 → 主 Claude: "起个子 AI 去 review init.lua"
2. 主 Claude: spawn_cli() 起子 Claude
3. 主 Claude: send_message(to="reviewer", body="review init.lua 的错误处理")
4. 子 Claude: fetch_inbox() → 收到任务 → 开始干活
5. 子 Claude: send_message(to="lead", body="发现3个问题：...")
6. 主 Claude: fetch_inbox() → 拿到结果 → 继续
7. 你随时可以切 tab 到子 Claude 打字介入
```

## 需要做的事

### 启动 mcp_agent_mail
```bash
# 安装
cd /tmp/mcp_agent_mail && pip install -e .
# 或者 uv
uvx mcp-agent-mail serve-http --port 8765
```

### 配置每个 AI CLI 连同一个 server
```json
{
  "mcpServers": {
    "mcp-agent-mail": {
      "type": "http",
      "url": "http://127.0.0.1:8765/api/",
      "headers": { "Authorization": "Bearer xxx" }
    }
  }
}
```

### system prompt 约定
每个 AI 的 system prompt 里加：
- 启动时 `register_agent` 注册身份
- 每完成一步 `fetch_inbox` 检查消息
- 任务完成后 `send_message` 汇报结果

## 满足目标情况

| 目标 | 满足 | 说明 |
|---|---|---|
| AI 调 AI | ✅ | spawn_cli + send_message |
| 结构化通信 | ✅ | MCP tool 调用，JSON 参数和返回值 |
| 完成通知 | 🔶 | 轮询 fetch_inbox，不是实时推送 |
| 人可介入 | ✅ | 切 tab 直接打字 |
| 人可观察 | ✅ | 每个 AI 都在 terminal 里 |
| 多 AI 支持 | ✅ | Claude/Gemini/Codex 都能连 |
| 文件冲突 | ✅ | file_reservation |

## 已知限制

1. **不是实时推送** — 子 AI 干完发消息后，主 AI 要等下次 fetch_inbox 才知道
2. **需要 system prompt 约定** — AI 不会自动去查收件箱，要在 prompt 里教它
3. **mcp_agent_mail 是外部依赖** — 需要单独启动和维护
4. **任务调度靠约定** — 没有 task queue，用 thread_id + topic 自己组织

## 相关文件

- agent_api.lua — 进程管理层
- mcp_agent_mail — https://github.com/Dicklesworthstone/mcp_agent_mail
- [目标](ai-to-ai-goal.md) | [方案对比](ai-to-ai-solutions.md) | [SDK-URL](ai-to-ai-sdk-url.md) | [Codex](ai-to-ai-codex-appserver.md)
