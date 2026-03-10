# Session Bus：多 Agent 协作运行时

## 核心概念

一个中央消息总线，多个 AI coding agent 通过 ACP 接入，以 coordinator + worker 主从模式协作。人类可随时介入。

**不是聊天工具，是协作运行时。** 频道里的消息主要是任务指令和状态汇报，不是讨论。

```
Human（随时介入）
  │
  ▼
Coordinator（主导者，1 个）
  │ 分解任务、分配、协调卡点、汇总结果
  │
  ├──→ Worker A ──→ 干活 → 汇报结果/卡点
  ├──→ Worker B ──→ 干活 → 汇报结果/卡点
  └──→ Worker C ──→ 干活 → 汇报结果/卡点

  所有通信经过 Session Bus（nvim 中间层）
```

### 角色分工

| 角色 | 职责 | 典型 agent |
|------|------|-----------|
| Coordinator | 拆任务、分配、协调、收敛结果 | Claude / Gemini |
| Worker | 执行具体任务，汇报进度和卡点 | 任意 AI CLI |
| Human | 发起需求，审批关键决策，处理 agent 解决不了的问题 | 你 |

### 为什么是主从而不是平等

- token 消耗可控：worker 只收到和自己相关的指令，不需要读所有人的闲聊
- 不会抢话/重复劳动：coordinator 明确分工，谁干什么清清楚楚
- 收敛快：有人拍板，不会陷入无限讨论

## 与现有方案的区别

| | 现有 task-system | Session Bus |
|---|---|---|
| 通信方式 | 文件系统（task.md / status / result.md） | ACP JSON-RPC stdin/stdout |
| 拓扑 | 人 → agent（一对一指挥） | coordinator → workers（主从 + 人介入） |
| agent 间协作 | 无，各干各的 | coordinator 协调，worker 间可通过频道沟通 |
| 人的角色 | 主导者，分配任务 | 可主导也可委托给 coordinator |

## 运行机制

### 1. Agent 接入

每个 agent 通过 ACP spawn，启动时收到 system prompt：

```
你是 [角色名]，擅长 [能力]。
你正在参与一个多 agent 协作会话。

团队成员：
- Gemini：架构设计、方案评审
- Claude：代码实现、重构
- Copilot：快速补全、测试生成

协作规则：
- 有人 @你 或话题与你相关时回复
- 主动认领你擅长的任务
- 卡住时在频道里说，其他人会帮你
- 不确定的事情先讨论再动手
```

### 2. 主动发言机制

Agent 不是把每句话都发到频道里。Bus 给每个 agent 注册一个 ACP tool `bus_post`，agent 需要协作时主动调用：

```
Agent 内部执行过程（不进频道）：
  读文件 → 分析代码 → 写代码 → 跑测试 → ...

Agent 主动发到频道的（调用 bus_post）：
  - 任务完成汇报："auth middleware 写好了，PR #12"
  - 卡点求助："token 刷新逻辑不确定，需要 coordinator 决策"
  - 状态更新："开始处理子任务 2"
```

ACP tool 定义：

```json
{
  "name": "bus_post",
  "description": "发送消息到协作频道。仅在需要汇报结果、提出卡点、请求协助时使用。内部思考和执行过程不要发。",
  "parameters": {
    "type": { "enum": ["done", "blocked", "progress", "question"] },
    "content": { "type": "string" }
  }
}
```

这样 token 消耗就很低——agent 闷头干活时不产生频道消息，只有关键节点才通信。

### 3. 消息总线

Bus 维护的状态：

```lua
session = {
  id = "session-001",
  messages = {                    -- 只有主动发言才进这个列表
    { id = 1, from = "human", type = "task", content = "给项目加 JWT 认证" },
    { id = 2, from = "coordinator", type = "assign", content = "Claude 负责 middleware，Gemini 负责方案评审" },
    { id = 3, from = "worker:claude", type = "progress", content = "开始写 auth middleware" },
    { id = 4, from = "worker:claude", type = "blocked", content = "token 刷新策略不确定" },
    { id = 5, from = "coordinator", type = "decision", content = "用 refresh token rotation" },
    { id = 6, from = "worker:claude", type = "done", content = "middleware 完成，PR #12" },
  },
  agents = {
    coordinator = { cursor = 6, status = "idle", role = "coordinator", cli = "gemini" },
    claude = { cursor = 5, status = "working", role = "worker", cli = "claude" },
  },
  human = {
    takeover = nil,             -- nil 表示没有私聊，"claude" 表示正在私聊 claude
    -- takeover 期间该 worker 的 ACP 通道归人类独占
  },
}
```

### 4. 消息路由

```
bus_post 调用进来 → 追加到 messages → 按规则推送：
  - coordinator 的消息 → 推给目标 worker（或广播）
  - worker 的消息 → 推给 coordinator
  - human 的消息 → 推给 coordinator（由 coordinator 决定是否转发）
```

不是全量广播，而是**经过 coordinator 中转**。Worker 之间默认不直接通信，需要时由 coordinator 转发。

### 6. 人类介入机制

人类有两种交互方式：

**频道发言**：在 bus buffer 里直接说话，所有人可见（经 coordinator 路由）

**私聊介入**：切到某个 worker 的 ACP 会话，一对一直接对话

私聊介入是高优先级事件，触发状态广播：

```
Human 切入 worker:claude 的私聊
  ↓
Bus 广播系统事件：{ type: "human_takeover", target: "worker:claude" }
  ↓
Coordinator 收到 → 暂停对 claude 的指令调度
其他 worker 收到 → 如果依赖 claude 的产出，知道要等
  ↓
Human 和 claude 一对一对话（不经过 bus，直接 ACP）
  ↓
Human 退出私聊
  ↓
Bus 广播：{ type: "human_release", target: "worker:claude", summary: "调整了 token 过期策略" }
  ↓
Coordinator 恢复调度，根据 summary 决定是否需要调整其他任务
```

关键规则：
- 人类介入时，该 worker 的 ACP 通道归人类独占，coordinator 不能同时发指令
- 退出时附带 summary，让 coordinator 和其他人知道发生了什么变化
- 人类也可以在私聊里直接给 worker 下指令，绕过 coordinator（紧急情况）

nvim UI 支持：
- bus buffer 里能看到所有 agent 状态，包括"human 正在私聊 claude"
- 快捷键切入某个 agent 的私聊 buffer（类似 tab 切换）
- 退出私聊时弹 input 框让你写 summary（可选，也可以自动生成）

### 7. 协作流程示例

```
Human: "给这个项目加上 JWT 认证"
  ↓ 推给 coordinator
Coordinator（内部思考：分析需求，拆子任务）
Coordinator → bus_post: "分配任务：Claude 写 auth middleware + 路由守卫，Copilot 写测试"
  ↓ bus 推给 claude 和 copilot
Claude（闷头干活：读代码、写 middleware、调试...）
Claude → bus_post(blocked): "token 刷新逻辑不确定，单次还是 rotation？"
  ↓ 推给 coordinator
Coordinator → bus_post(decision): "用 rotation，过期时间 24h"
  ↓ 推给 claude
Claude（继续干活...）
Claude → bus_post(done): "middleware + 路由守卫完成"
  ↓ 推给 coordinator
Coordinator → bus_post: "所有子任务完成，@Human 请 review"
  ↓ 推给 human
Human: "LGTM" 或 "token 过期时间改成 7 天"
```

## 技术架构

```
lua/core/
├── acp_client.lua          ← ACP 协议层（JSON-RPC over stdio）
│   ├── spawn(cmd, args)
│   ├── send(agent_id, method, params)
│   ├── on_message(agent_id, cb)
│   └── close(agent_id)
│
├── session_bus.lua          ← 协作运行时（本文档的核心）
│   ├── create_session(opts)
│   ├── add_agent(session_id, agent_config)
│   ├── post_message(session_id, from, content)
│   ├── broadcast(session_id)       ← 推送未读消息给相关 agent
│   ├── get_agent_status(session_id)
│   ├── human_takeover(session_id, agent_id)   ← 人类切入私聊
│   ├── human_release(session_id, summary)     ← 人类退出私聊
│   └── close_session(session_id)
│
└── session_ui.lua           ← nvim buffer 渲染
    ├── open_session_buffer(session_id)
    ├── render_messages()
    └── input_handler()          ← 人的输入 → post_message
```

### ACP 消息映射

| 协作动作 | ACP 方法 |
|----------|----------|
| 推送频道消息给 agent | `messages/create`（发用户消息） |
| agent 回复 | `messages/stream`（流式响应） |
| agent 请求权限（执行命令等） | ACP tool approval flow |
| 人审批权限 | nvim popup → ACP approval response |

### 与现有 task-system 的关系

共存，不替代：
- task-system：简单的"派任务 → 等结果"场景，文件通信，轻量
- session bus：需要多 agent 协作的复杂场景，ACP 通信，重量级

## 待解决

- [ ] ACP 协议里怎么注册自定义 tool（bus_post）给 agent
- [ ] agent 执行文件操作时的冲突（两个 worker 改同一个文件）— coordinator 分配时需要避免
- [ ] session 持久化（关掉 nvim 后能恢复）
- [ ] coordinator 自身用哪个 CLI — 需要选一个推理能力强、成本可控的
- [ ] worker 失败/超时的处理策略

## 调研清单

要做这个东西，不是从 0 造轮子，先看别人怎么做的，再抽取能用的。

### 第一层：ACP 协议本身

| 调研项 | 目标 | 来源 |
|--------|------|------|
| ACP 完整消息类型 | 搞清楚能发什么、收什么、tool 怎么注册 | [协议规范](https://github.com/zed-industries/agent-client-protocol) |
| ACP tool registration | 能否给 agent 注册自定义 tool（bus_post） | 协议规范 + SDK 源码 |
| `gemini --acp` 实际通信 | 抓一次完整的请求/响应流程 | 本地验证 |

### 第二层：多 agent 编排框架

看别人的"群聊/协作"怎么做的，重点学消息路由、角色分配、冲突处理。

| 项目 | 关注点 | 链接 |
|------|--------|------|
| Claude Code team 模式 | lead + teammates 主从模式，任务分配，消息传递机制 | 本地 claude 源码 / 文档 |
| agent-team (nekocode) | 20+ agent 编排，ACP 管理，角色系统 | [GitHub](https://github.com/nekocode/agent-team) |
| acpx | headless ACP client，看它怎么做会话管理 | [GitHub](https://github.com/openclaw/acpx) |
| codecompanion.nvim | nvim 里的 ACP client 实现，握手/路由/UI | 源码 |
| team-anya | 多 CC 进程协作，CCBroker 中转，崩溃恢复 | 已有研究 |
| OpenHands / SWE-agent | 多 agent 协作的 task 分配和状态管理 | GitHub |
| CrewAI / AutoGen | Python 多 agent 框架，角色系统、对话管理、任务委派 | GitHub |

### 第三层：通信/消息总线模式

不限于 AI 领域，看通用的消息总线/事件系统怎么设计的。

| 参考 | 关注点 |
|------|--------|
| IRC/Matrix 协议 | 频道模型、消息路由、权限层级 |
| Zulip topic 模型 | 频道内按 topic 分流，类似 coordinator 分任务 |
| Actor 模型 (Erlang/Akka) | 消息传递、状态隔离、supervisor 模式 |

### 第四层：nvim 集成

| 调研项 | 目标 |
|--------|------|
| codecompanion 的 ACP + buffer 渲染 | 它怎么在 nvim buffer 里渲染 agent 输出 |
| Zed 的 ACP client | 编辑器侧怎么做握手、权限弹窗、多 agent 管理 |
| nvim 里的 chat UI 方案 | 现有的 chat buffer 实现（codecompanion / avante / CopilotChat） |

## 迭代路线

### Phase 0：调研（当前）
- 读 ACP 协议规范
- 研究上面列的开源项目，重点是 agent-team、acpx、Claude Code team 模式
- 输出：每个项目一份研究笔记到 `research/`

### Phase 1：单 agent ACP 通信
- nvim 里 spawn `gemini --acp`，发消息收回复
- 实现 `acp_client.lua` 基础协议层
- 验证 tool registration（能否注册 bus_post）

### Phase 2：双 agent + bus
- 两个 agent（比如 gemini coordinator + gemini worker）
- session_bus.lua 基础版：消息列表、cursor、路由
- 简单的 nvim buffer 渲染

### Phase 3：人类介入
- 私聊切入/退出机制
- takeover 状态广播
- bus buffer UI 完善

### Phase 4：多 CLI 混合
- 接入 Claude Code（wrapper 或等原生 ACP）
- 不同 CLI 做不同角色
- 生产可用

## 已解决（通过主从模式）

- ~~成本控制~~：bus_post 主动发言 + coordinator 中转，不再全量广播
- ~~多 agent 抢话~~：coordinator 分配，worker 只干自己的
- ~~无限讨论~~：coordinator 拍板，不需要共识
