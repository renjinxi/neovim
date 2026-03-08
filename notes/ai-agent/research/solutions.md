# AI-to-AI 通信：方案对比

## 方案一：Terminal 模式（现有）

通过 nvim terminal 启动 CLI，用 stdin/stdout 原始文本通信。

```
Claude-1 → agent_api.spawn_cli() → nvim terminal → Claude-2
Claude-1 → send_to_terminal()    → Claude-2 stdin
Claude-1 → get_terminal_output() → 读 terminal buffer
人       → 切 tab 直接打字        → Claude-2 stdin
```

### 优势
- ✅ **人可直接介入** — 切 tab 就能打字，和正常用 CLI 一模一样
- ✅ **实现简单** — 已有 agent_api.lua，能用
- ✅ **多 CLI 通用** — claude / gemini / codex 都是 terminal 进程
- ✅ **所见即所得** — 人能看到完整的 CLI 输出

### 劣势
- ❌ **通信不结构化** — 读 terminal buffer 是原始文本 + ANSI 颜色码
- ❌ **无法判断完成** — 只能轮询猜测子 AI 是否跑完
- ❌ **解析困难** — 从 terminal 输出中提取有用信息靠正则/猜测
- ❌ **权限处理** — 子 AI 弹权限确认时，主 AI 不知道，只有人切过去才能处理

### 适用场景
- 人主导、AI 辅助的场景
- 不需要主 AI 精确解析子 AI 输出的场景
- 快速原型验证

---

## 方案二：ACP 协议模式（codecompanion / avante 的方式）

通过 `vim.system()` 启动后台进程，JSON-RPC 2.0 over stdio 通信。

```
nvim (Client) → stdin  → JSON-RPC → claude-agent-acp (Agent)
nvim (Client) ← stdout ← JSON-RPC ← claude-agent-acp (Agent)
```

### 优势
- ✅ **结构化通信** — JSON-RPC 消息，精确解析
- ✅ **明确完成信号** — `stopReason: end_turn`
- ✅ **权限处理** — `request_permission` 消息，可弹 nvim UI 确认
- ✅ **流式更新** — `session/update` 实时推送思考过程和工具调用
- ✅ **多 agent 支持** — codecompanion 已适配 9 个 CLI

### 劣势
- ❌ **人无法直接介入** — 后台进程，没有 terminal UI
- ❌ **需要自建 UI** — 要用 nvim buffer 渲染 agent 输出，人才能看到
- ❌ **接管困难** — 人想打字介入需要通过 buffer → JSON-RPC 转换
- ❌ **不是原生 CLI 体验** — 和直接用 `claude` 命令的感觉完全不同
- ❌ **依赖 CLI 支持 ACP** — 不是所有 CLI 都有 ACP 模式

### 适用场景
- AI 全自动编排，人只做审批
- 需要精确解析 AI 输出的场景
- 构建类似 codecompanion 的 chat UI

---

## 方案三：SDK-URL 模式（mc / team-anya 的方式）

通过 `--sdk-url` 参数让 Claude Code CLI 反连到你的 WebSocket Server，实现程序化控制。

```
你的程序（WS Server）                Claude Code CLI
    |-- 起 WS Server on 随机端口           |
    |   spawn claude --sdk-url ws://127.0.0.1:{port}/ws/cli/{sessionId}
    |<---- Claude 主动反连到你的 WS -------|
    |---- 发 JSON（user prompt）---------->|
    |<---- 收 JSON（stream/result）--------|
```

**不是 SDK 直调 API，而是 CLI 通过 WebSocket 被程序控制。CLI 自带的所有工具能力都保留。**

### 优势
- ✅ **结构化通信** — NDJSON over WebSocket，精确解析
- ✅ **明确完成信号** — `result` 消息，含 usage/cost/turns
- ✅ **权限控制** — `control_request/response` 协议层审批
- ✅ **CLI 工具能力保留** — 文件读写、bash 执行等全部可用
- ✅ **多实例管理** — CCBroker 模式，可同时管理多个 CC 进程
- ✅ **崩溃恢复** — team-anya 实现了自动重建会话
- ✅ **可劫持 API 目标** — 设置 ANTHROPIC_BASE_URL 可指向代理/其他模型

### 劣势
- ❌ **人无法直接介入** — 后台进程，没有 terminal UI
- ❌ **仅 Claude Code 支持** — `--sdk-url` 是 Claude Code 特有参数，gemini/codex 没有
- ❌ **需要 WS Server** — 要自己实现 WebSocket 服务端
- ❌ **协议未公开** — 从 team-anya 逆向来的，可能随版本变化
- ❌ **环境变量清洗** — 必须清除 CLAUDECODE/CLAUDE_CODE_* 防嵌套检测

### 实际案例

**mc 项目**：语音驱动 AI 调度。dispatcher Agent 监听会议转录，识别"启动"指令后通过 claude-launcher 启动新 CC 实例。

**team-anya 项目**：AI 团队协作。Loid（策划）通过 MCP 工具调度 Yor（行动），每个角色是独立的 CC 进程，通过 Server 中转通信。

### 适用场景
- 后端服务中的 AI 编排（team-anya）
- AI 调度 AI 的自动化场景
- 需要精确控制 AI 行为但保留 CLI 工具能力的场景

---

## 方案四：混合模式（待探索）

结合 Terminal 模式的人工介入能力和结构化通信的优势。

```
可能的形态：
1. Terminal 模式 + 输出解析增强（正则/标记检测完成状态）
2. ACP 模式 + nvim buffer 渲染（模拟 terminal 体验）
3. CLI stream-json 模式（claude --output-format=stream-json）
4. Terminal 模式 + SDK 辅助通道（terminal 给人看，SDK 做结构化通信）
```

### 待验证
- Claude CLI 的 `--output-format=stream-json` 能否在 terminal 中使用
- 是否能同时保持 terminal 交互和结构化输出
- mc 项目的 sdk-url 方案能否集成到 nvim 中

---

## 对比总结

| 维度 | Terminal | ACP | SDK-URL | 混合 |
|------|----------|-----|---------|------|
| 通信结构化 | ❌ 原始文本 | ✅ JSON-RPC | ✅ NDJSON/WS | 🔶 待定 |
| 完成检测 | ❌ 轮询猜测 | ✅ stopReason | ✅ result 消息 | 🔶 待定 |
| 人可介入 | ✅ 切 tab 打字 | ❌ 需自建 UI | ❌ 后台进程 | 🔶 待定 |
| 人可观察 | ✅ 看 terminal | 🔶 需渲染 buffer | ❌ 后台进程 | 🔶 待定 |
| 实现复杂度 | ✅ 已有 | 🔶 中等 | 🔶 中等（需 WS Server） | ❌ 高 |
| 多 CLI 支持 | ✅ 通用 | 🔶 需适配 | ❌ 仅 Claude Code | 🔶 待定 |
| AI 工具能力 | ✅ CLI 自带 | ✅ CLI 自带 | ✅ CLI 自带 | 🔶 待定 |
| 权限控制 | ❌ 人工切 tab | ✅ request_permission | ✅ control_request | 🔶 待定 |
| 崩溃恢复 | ❌ 无 | ❌ 无 | ✅ team-anya 已实现 | 🔶 待定 |

## 核心矛盾

**结构化通信** 和 **人可介入** 目前是冲突的：
- 结构化 → 后台进程 / API → 人看不到、摸不着
- 人可介入 → terminal → 原始文本、难解析

**这是我们需要解决的核心问题。**

## 待探索

1. ~~查看 mc 项目的 sdk-url 实现细节~~ ✅ 已完成，见 [sdk-url 研究](ai-to-ai-sdk-url.md)
2. 测试 Claude CLI 的 stream-json 模式
3. 研究是否有办法在 terminal 模式下增加结构化信号
4. 评估 codecompanion 的 ACP + buffer 渲染方案的人工介入体验
5. 研究 Gemini / Codex 等其他 CLI 是否有类似 sdk-url 的程序化控制方式
6. 探索混合方案：SDK-URL 做通信 + nvim buffer 渲染输出模拟 terminal 体验
