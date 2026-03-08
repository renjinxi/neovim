# Codex App Server 架构研究

来源: https://openai.com/index/unlocking-the-codex-harness/

## 它解决什么问题

Codex agent 需要同时跑在 CLI、VS Code、Web、桌面 App 里。与其每个客户端各实现一套 agent 逻辑，不如抽出一个统一的运行时。

## 架构

```
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│  CLI/TUI │ │  VS Code │ │   Web    │ │ Desktop  │
└────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘
     └────────────┴─────┬──────┴────────────┘
                        │ 双向 JSON-RPC
                        ↓
              ┌─────────────────────┐
              │   Codex App Server  │
              │  ┌───────────────┐  │
              │  │ stdio reader  │  │ ← 接收客户端消息
              │  │ msg processor │  │ ← core事件 → 稳定UI事件
              │  │ thread mgr    │  │ ← 管理多个会话
              │  │ core threads  │  │ ← 跑 agent loop
              │  └───────────────┘  │
              └─────────────────────┘
                        │
              ┌─────────────────────┐
              │    Codex Core       │
              │  (agent loop +      │
              │   tools + sandbox)  │
              └─────────────────────┘
```

## 三层状态模型

这是最核心的设计。

```
Thread（长期会话容器）
  ├── create / resume / fork / archive
  ├── 持久化 event history
  │
  └── Turn（一次用户请求触发的工作单元）
        │
        ├── Item: 用户消息
        ├── Item: 工具调用
        │     └── 可能触发 requestApproval → 暂停等人回复
        ├── Item: agent 流式输出
        │     └── started → delta* → completed
        └── Item: diff / 审批结果
```

每个 Item 有明确生命周期：`started → delta* → completed`，天然适合 UI 渲染。

## 协议流程

### 1. 初始化握手

```json
→ {"method": "initialize", "params": {"clientInfo": {"name": "codex_vscode", "version": "0.1.0"}}}
← {"result": {"userAgent": "..."}}
```

协商版本、feature flags、默认行为。

### 2. 创建会话 + 发消息

```
→ 创建 thread
→ 启动 turn（附带用户消息）
← thread/started
← turn/started
← item/started（用户消息）
← item/completed
```

### 3. 工具执行 + 审批

```
← item/started（工具调用：pnpm test）
← item/commandExecution/requestApproval  ← agent 主动问客户端
→ allow                                   ← 客户端回复
← item/completed
```

审批是协议的一部分，不是 UI 弹窗逻辑。

### 4. 流式输出

```
← item/started（agent message）
← agentMessage/delta
← agentMessage/delta
← item/completed
← turn/completed
```

## 关键设计决策

### 1. 双向协议
不是 request/response，是双向的。Server 会主动向客户端发请求（审批）。

### 2. 协议翻译层
message processor 把 core 内部事件翻译成稳定的 UI 事件。底层 runtime 可以随便改，客户端不受影响。

### 3. 审批进协议层
审批不是前端私有逻辑，而是协议事件。可追踪、可暂停 turn、跨客户端一致。

### 4. Thread 持久化
客户端断线重连后能恢复完整历史。不同设备/界面能看到同一条时间线。

## 和我们研究的其他方案的关系

| | ACP | SDK-URL | Codex App Server |
|---|---|---|---|
| 传输层 | stdio | WebSocket | stdio (JSON-RPC) |
| 协议 | JSON-RPC 2.0 | NDJSON | JSON-RPC (自定义) |
| 状态模型 | session/prompt | session_id | thread/turn/item |
| 审批 | request_permission | control_request | requestApproval |
| 持久化 | 无 | 无 | thread history |
| 多端复用 | 单客户端 | 单客户端 | 多客户端共享 |

本质上是同一类思路的不同成熟度：
- ACP = 最小可用
- SDK-URL = 加了 WebSocket 和多实例管理
- Codex App Server = 完整的 agent runtime 平台

## 对我们的启发

1. **thread/turn/item 三层模型**值得借鉴 — 不管最终用什么传输层
2. **协议翻译层**的思路 — 底层 runtime 和 UI 解耦
3. **审批进协议**而不是散在 UI 里
4. 但 Codex App Server 也没解决"人直接切 tab 打字"的问题 — 人的介入还是通过客户端 UI → 协议 → agent
