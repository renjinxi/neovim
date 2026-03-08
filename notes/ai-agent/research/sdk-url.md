# SDK-URL 模式研究

基于 mc 项目和 team-anya 项目的源码研究。

## 什么是 `--sdk-url`

Claude Code CLI 的一个参数，让 CLI 进程不走 stdin/stdout 交互，而是**主动反连到你指定的 WebSocket Server**。

```
你的程序（WS Server）                Claude Code CLI
    |                                      |
    |-- 起 WS Server on 随机端口           |
    |                                      |
    |   spawn claude --sdk-url ws://127.0.0.1:{port}/ws/cli/{sessionId}
    |                                      |
    |<---- Claude 主动连接到你的 WS -------|
    |                                      |
    |---- 发 JSON 消息（user prompt）----->|
    |<---- 收 JSON 消息（stream/result）---|
```

关键：**反向连接**。不是你连 Claude，是 Claude 连你。

## CLI 参数组合

```bash
claude \
  --sdk-url ws://127.0.0.1:{port}/ws/cli/{sessionId} \
  --print \
  --output-format stream-json \
  --input-format stream-json \
  --dangerously-skip-permissions \
  --verbose \
  --append-system-prompt "角色设定..."
```

## 通信协议

WebSocket 上传输 NDJSON（换行分隔的 JSON）。

### 消息类型

| 方向 | type | 含义 |
|------|------|------|
| CLI → Server | `system` (subtype: init) | 初始化完成，返回 session_id |
| Server → CLI | `user` | 发送 prompt |
| CLI → Server | `stream_event` | 流式输出增量（content_block_delta） |
| CLI → Server | `assistant` | 完整助手消息 |
| CLI → Server | `result` | 一轮对话结束，含 usage/cost/turns |
| CLI → Server | `control_request` | 工具审批请求（can_use_tool） |
| Server → CLI | `control_response` | 审批结果（allow/deny） |
| CLI → Server | `keep_alive` | 心跳 |

### 发送 prompt 格式

```json
{
  "type": "user",
  "message": { "role": "user", "content": "你的提示词" },
  "session_id": "从init消息获取",
  "parent_tool_use_id": null
}
```

### 环境变量清洗

启动子进程前必须清除：
- `CLAUDECODE` / `CLAUDE_CODE_*` — 防止嵌套检测报错
- `HTTP_PROXY` / `HTTPS_PROXY` — 避免代理冲突

可通过设置 `ANTHROPIC_BASE_URL` + `ANTHROPIC_AUTH_TOKEN` 劫持 API 目标。

---

## mc 项目：语音驱动 AI 调度

### 架构

```
麦克风 → server.js(ASR) → 转录文件
                              ↓
                    dispatcher.js（调度 Agent）
                         ↓ 识别"启动"指令
                         ↓ 调用 claude-launcher
                    新 Claude Code 实例（工作 Agent）
```

### 两种模式

1. **mc-assistant** — AI 消费转录数据，生成会议摘要
2. **dispatcher** — AI 监听转录，识别指令后启动新 AI 实例

### 人可介入

两个模式都支持 stdin 手动输入，人随时可以插入指令。

---

## team-anya 项目：AI 团队协作系统

### 架构

```
┌─────────────────────────────────────────────┐
│              Server (Fastify)                │
│                                             │
│  飞书/HTTP → MessageIntake → LoidBrain      │
│                                             │
│  CCBroker (统一 CC 进程管理器)               │
│  ├── Loid (策划者) ← WS → CC CLI           │
│  ├── Yor  (行动者) ← WS → CC CLI           │
│  └── Franky (协作者) ← WS → CC CLI         │
│                                             │
│  每个 CC 实例有独立的 MCP Server             │
│  ├── Loid MCP: 指挥工具 (spawn/rework/approve) │
│  ├── Yor MCP: 汇报工具 (deliver/block/progress) │
│  └── Franky MCP: 专项工具                   │
└─────────────────────────────────────────────┘
```

### 三个 AI 角色

| 角色 | 职责 | 生命周期 |
|------|------|----------|
| Loid（策划者） | 需求理解、任务拆解、结果审核 | 长驻，按 chatId 维护 |
| Yor（行动者） | 编码、测试、Git 操作 | 任务级，一个任务一个进程 |
| Franky（协作者） | 专项持续协作 | Topic 级 |

### 协作流程

```
人类消息 → 飞书 → Loid 分析
  → Loid 调 MCP: yor.spawn → 启动 Yor CC 实例
  → Yor 自主执行 → task.deliver
  → Loid 审核 → yor.approve 或 yor.rework
```

AI 之间不直接通信，通过 Server 进程内的 MCP 工具中转。

### 关键设计

- **反向连接**：Server 是 WS Server，CLI 是 WS Client
- **MCP 隔离**：每个角色工具集不同，权限分离
- **崩溃恢复**：CC 实例崩溃时自动重建会话
- **ScopeChecker**：可在协议层拦截危险操作

---

## SDK-URL 模式评估

### 对我们目标的满足度

| 目标 | 满足度 | 说明 |
|------|--------|------|
| AI 调 AI | ✅ 完全满足 | 程序化控制，结构化通信 |
| 实时通信 | ✅ 完全满足 | WebSocket 流式，有 result 完成信号 |
| 人可介入 | ❌ 不满足 | 后台进程，没有 terminal UI |
| 多 CLI 支持 | ❌ 不满足 | 仅 Claude Code 支持 --sdk-url |

### 核心限制

**人无法像用 `:AI` 一样切过去直接打字。** SDK-URL 模式下 Claude 是后台进程，没有 terminal。mc 项目通过 stdin 做了简单的人工输入，但体验和直接用 CLI 完全不同。

### 但它解决了什么

- 结构化通信（JSON over WebSocket）
- 明确的完成信号（result 消息）
- 权限控制（control_request/response）
- 多实例管理（CCBroker）
- 崩溃恢复

---

## 与其他方案的关系

```
Terminal 模式    → 人可介入 ✅，结构化 ❌
ACP 模式        → 人可介入 ❌，结构化 ✅（JSON-RPC over stdio）
SDK-URL 模式    → 人可介入 ❌，结构化 ✅（NDJSON over WebSocket）
```

SDK-URL 本质上和 ACP 是同一类方案（程序化控制 AI），只是传输层不同：
- ACP = JSON-RPC over stdio
- SDK-URL = NDJSON over WebSocket

两者都牺牲了人的直接介入能力，换取了结构化通信。
