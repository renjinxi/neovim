# #29 ACP 架构重设计

claude1 | 2026-03-16

---

## 一、当前架构总览

```
init.lua          — 入口：命令注册、单例管理、RPC 桥接
  ├── chat.lua    — 1v1 对话 UI + client 生命周期
  ├── bus.lua     — 频道 UI + 消息路由 + agent 编排 + main 队列
  ├── client.lua  — ACP 协议：spawn/握手/prompt/terminal
  ├── adapter.lua — CLI spawn 配置 + system prompt
  └── store.lua   — 频道快照持久化
```

5 个模块，~1700 行。看似分层清晰，实际存在严重的职责混杂和耦合问题。

---

## 二、当前问题

### 2.1 Bus 是上帝对象（God Object）

bus.lua 当前 854 行，承担了 **7 个不同职责**：

| 职责 | 行数估算 | 应该在哪 |
|------|----------|----------|
| 频道 UI（buffer/window/winbar/scroll） | ~200 | 独立 UI 模块 |
| 消息存储 + 渲染 | ~80 | 消息模型 |
| 输入框管理 | ~50 | UI 模块 |
| @mention 路由 | ~50 | 路由模块 |
| agent 生命周期（add/cleanup/status） | ~100 | agent 注册表 |
| main 串行队列 + 推送 | ~120 | 调度模块 |
| 子 agent prompt 发送 + 兜底回复 | ~120 | 调度模块 |

**结果**：改任何一个功能都要在 bus.lua 里翻来翻去，Bug #26/#27 本质上是因为 Bus 同时管 UI、管调度、管 agent 状态，导致状态同步困难。

### 2.2 Chat 双模式导致职责模糊

Chat 同时服务于两个场景：
- **独立模式**：用户直接对话，Chat 拥有 client
- **Bus 模式**：Bus 创建 Chat 只为了 buffer 渲染，client 由 Bus 管理

两种模式共享 `_on_update`、`_submit_input`、`streaming` 等字段，通过 `if self.bus then` 分叉。这导致：
- Chat 的 `streaming` 状态需要被 Bus 外部修改（bus.lua L549-553, L570-574）
- Chat 的 `_on_update` 做完自己的事还要 forward 给 Bus（chat.lua L358-362）
- Bug #27 就是这种 monkey-patch 式的状态同步出了问题

### 2.3 init.lua 是隐式的全局状态中心

init.lua 维护 `active_chats` 和 `active_bus`（单例），所有模块通过 `pcall(require, "acp.init")` 反向依赖它：
- bus.lua `_find_main_chat()` 和 `_notify_main_chat()` 都要 require init 再遍历 active_chats
- chat.lua `on_ready` 回调直接操作 `active_bus.agents["main"]`

这形成了**循环依赖**：init → bus → init、init → chat → init。

### 2.4 Client 和 Chat 的关系不清

Client 是纯协议层，但它和 Chat 之间缺少明确的所有权语义：
- 独立 Chat：Chat 创建并拥有 Client
- Bus agent：Bus 通过 Chat 间接创建 Client，但直接操作 `agent.client`
- Main agent：Client 由 Chat 创建，但被 Bus `agents["main"]` 引用

同一个 Client 可能同时被 Chat 和 Bus 两个对象持有和操作——这就是 Bug #27 的根因。

### 2.5 单例 Bus 阻塞多频道

`active_bus` 是单例。想支持多频道（#28）就要改 init.lua 的全部调度逻辑。想支持频道树（P4）更是无处下手。

### 2.6 缺少 Task 层（codex1 #21）

消息和任务没有区别，所有协作状态都编码在消息流里。频道会话越长，"谁在做什么"越不清楚。

---

## 三、目标架构

### 3.1 设计原则

1. **单一职责**：每个模块只做一件事
2. **所有权明确**：每个资源有且只有一个 owner
3. **事件驱动**：模块间通过事件通信，不互相 require
4. **数据和展示分离**：逻辑层不碰 buffer/window

### 3.2 目标模块图

```
                          ┌─────────────┐
                          │  init.lua   │  入口：命令注册、Registry 初始化
                          └──────┬──────┘
                                 │
                          ┌──────▼──────┐
                          │  registry   │  全局注册表：channels + chats + agents
                          └──────┬──────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                  │
       ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
       │   channel    │   │    agent    │   │    chat     │
       │  (原 bus)    │   │  registry   │   │  (独立UI)   │
       └──────┬──────┘   └──────┬──────┘   └─────────────┘
              │                  │
    ┌─────────┼─────────┐       │
    │         │         │       │
┌───▼──┐ ┌───▼──┐ ┌────▼──┐ ┌──▼───┐
│router│ │ task │ │ view  │ │client│  ACP 协议（不变）
└──────┘ └──────┘ └───────┘ └──────┘
```

### 3.3 模块职责重新划分

| 新模块 | 职责 | 来源 |
|--------|------|------|
| **client.lua** | ACP 协议：spawn/握手/prompt/terminal。**不变** | 现有 client.lua |
| **adapter.lua** | CLI spawn 配置。**不变** | 现有 adapter.lua |
| **agent.lua** | Agent 数据模型 + 生命周期。一个 agent = client + metadata | 从 bus.lua 抽出 |
| **channel.lua** | 频道逻辑层：消息存储、路由、调度。**无 UI** | 从 bus.lua 抽出 |
| **channel_view.lua** | 频道 UI：buffer/window/winbar/input/渲染 | 从 bus.lua 抽出 |
| **chat.lua** | 独立 1v1 对话 UI。**去掉 bus 模式** | 简化现有 chat.lua |
| **router.lua** | @mention 解析 + 路由规则 + depth 限制 | 从 bus.lua 抽出 |
| **scheduler.lua** | main 串行队列 + agent prompt 调度 + 超时 + 兜底 | 从 bus.lua 抽出 |
| **task.lua** | 轻量任务模型（#21） | 新增 |
| **registry.lua** | 全局注册表：channels/chats 管理 + 事件分发 | 从 init.lua 抽出 |
| **store.lua** | 持久化。**不变** | 现有 store.lua |
| **init.lua** | 命令注册。**大幅瘦身** | 现有 init.lua |

---

## 四、核心改动方案

### 4.1 Agent 数据模型独立

**问题**：当前 agent 是 bus.agents 里的匿名 table，字段散落在 bus.lua 各处。

**方案**：

```lua
-- agent.lua
local Agent = {}
Agent.__index = Agent

function Agent.new(name, opts)
    return setmetatable({
        name = name,
        kind = opts.kind or "spawned",  -- "local" | "spawned"
        adapter_name = opts.adapter_name,
        client = nil,
        status = "connecting",          -- connecting|idle|streaming|disconnected|error
        activity = nil,                 -- thinking|typing|Read File|...
        streaming = false,
        stream_buf = "",
        system_prompt = opts.system_prompt,
        prompted = false,
        -- task 关联
        current_task = nil,
    }, Agent)
end

function Agent:is_alive()
    return self.client and self.client.alive
end

function Agent:reset_stream()
    self.stream_buf = ""
    self.streaming = false
    self.activity = nil
end
```

**收益**：
- agent 状态操作集中，不再散落在 bus.lua 十几处
- 为 task 层提供 `current_task` 挂载点
- agent 可以独立于 channel 存在（多频道共享 agent 的前提）

### 4.2 Channel 逻辑层和 UI 层分离

**当前**：Bus = 逻辑 + UI，854 行一锅端。

**方案**：拆成 channel.lua（数据+逻辑）和 channel_view.lua（UI）。

```lua
-- channel.lua — 纯逻辑，不碰 vim.api
local Channel = {}

function Channel.new(opts)
    return setmetatable({
        id = opts.id or os.date("%Y%m%d-%H%M%S"),
        cwd = opts.cwd or vim.fn.getcwd(),
        messages = {},
        agents = {},        -- {name -> Agent}
        parent = nil,       -- 父频道引用（P4 频道树）
        children = {},      -- 子频道（P4）
        tasks = {},         -- {task_id -> Task}（#21）
        _scheduler = nil,   -- Scheduler 实例
        _router = nil,      -- Router 实例
    }, Channel)
end

function Channel:post(from, content, opts)
    local msg = { from = from, content = content, timestamp = os.time() }
    self.messages[#self.messages + 1] = msg
    -- 触发事件，UI 订阅后渲染
    self:_emit("message", msg)
    -- 路由
    if not (opts and opts.no_route) then
        self._router:route(content, from)
    end
end

function Channel:add_agent(name, agent)
    self.agents[name] = agent
    self:_emit("agent_changed", name, agent)
end
```

```lua
-- channel_view.lua — 纯 UI
local ChannelView = {}

function ChannelView.new(channel)
    local self = setmetatable({
        channel = channel,
        buf = nil, win = nil,
        input_buf = nil, input_win = nil,
    }, ChannelView)
    -- 订阅频道事件
    channel:on("message", function(msg) self:_render_message(msg) end)
    channel:on("agent_changed", function() self:_refresh_winbar() end)
    return self
end
```

**收益**：
- Channel 可以无 UI 运行（headless 频道、子频道汇报）
- UI 逻辑独立，可以为频道做不同视图（消息流 / task board / inspect 面板）
- P4 频道树只需要改 Channel 逻辑，不碰 UI

### 4.3 Scheduler 独立

**问题**：main 队列、超时、agent prompt 调度、兜底回复逻辑全部揉在 bus.lua 里。

```lua
-- scheduler.lua
local Scheduler = {}

function Scheduler.new(channel)
    return setmetatable({
        channel = channel,
        _main_busy = false,
        _main_queue = {},
        _drain_pending = false,
    }, Scheduler)
end

-- 推送给 main（串行队列 + 超时）
function Scheduler:push_to_main(content, from) ... end

-- 推送给子 agent（兜底回复 + self_posted 检测）
function Scheduler:push_to_agent(name, content, from) ... end

-- 队列排水
function Scheduler:_drain_queue() ... end
```

**收益**：
- 调度逻辑集中，超时、重试、背压（#24）都在这里加
- Channel 只管消息和 agent，不管调度策略

### 4.4 Router 独立

```lua
-- router.lua
local Router = {}

function Router.new(channel, scheduler)
    return setmetatable({
        channel = channel,
        scheduler = scheduler,
        max_depth = 5,
    }, Router)
end

function Router:route(content, from, depth)
    depth = depth or 0
    if depth >= self.max_depth then
        log("WARN", "route depth limit")
        return
    end
    for name in content:gmatch("@([%w_%-]+)") do
        if name ~= from and self.channel.agents[name] then
            self.scheduler:dispatch(name, content, from, depth + 1)
        end
    end
end
```

### 4.5 Chat 去掉 Bus 模式

**当前**：Chat 同时服务独立对话和 Bus 子 agent，通过 `self.bus` 分叉。

**方案**：
- Chat **只做独立 1v1 对话**，去掉所有 `if self.bus` 分支
- Bus 子 agent 的 buffer 渲染由 `channel_view.lua` 或独立的 `agent_view.lua` 负责
- Agent 直接持有 Client，不通过 Chat 间接持有

```
之前：Bus → Chat → Client（Bus 通过 Chat 间接管 Client）
之后：Channel → Agent → Client（Channel 通过 Agent 直接管 Client）
              ↑
          AgentView（可选，查看 agent 详细对话）
```

**收益**：
- 消除 Bug #27 的根因：不再有 Chat 和 Bus 同时操作 Client 的情况
- Chat 代码量减半，只做最纯粹的 1v1 对话
- Agent 的 on_update 处理在 Channel 侧统一管理

### 4.6 Registry 替代 init.lua 全局状态

```lua
-- registry.lua
local Registry = {}

function Registry.new()
    return setmetatable({
        channels = {},      -- {id -> Channel}
        chats = {},         -- {id -> Chat}
        _listeners = {},
    }, Registry)
end

function Registry:create_channel(opts) ... end
function Registry:create_chat(adapter_name, opts) ... end
function Registry:get_active_channel() ... end
function Registry:find_main_client() ... end
```

init.lua 瘦身为纯命令注册：

```lua
function M.setup()
    local reg = require("acp.registry").get()
    vim.api.nvim_create_user_command("Acp", function(opts)
        -- 全部转发给 registry
    end, { ... })
end
```

**收益**：
- 消除循环依赖
- 多频道支持（#28）：`channels` 是 table 不是单例
- Registry 可以发事件，UI 订阅刷新

### 4.7 Task 层（#21，轻量版）

```lua
-- task.lua
local Task = {}

function Task.new(opts)
    return setmetatable({
        id = "t-" .. os.time() .. "-" .. math.random(1000),
        title = opts.title,
        owner = opts.owner,         -- agent name
        requester = opts.requester, -- 谁派的
        status = "queued",          -- queued|running|blocked|done|failed
        artifacts = {},             -- 产出文件路径
        created_at = os.time(),
        finished_at = nil,
    }, Task)
end

function Task:start() self.status = "running" end
function Task:done(artifacts)
    self.status = "done"
    self.finished_at = os.time()
    self.artifacts = artifacts or {}
end
function Task:fail(reason) self.status = "failed" end
```

**不做**：workflow engine、状态机、自动重试。先只做数据模型和基本状态转换。

**接入点**：
- `scheduler:push_to_agent()` 时自动创建 task
- agent prompt 完成时标记 done/failed
- `channel_view` 的 winbar 显示 task 状态
- store.lua 快照包含 tasks

---

## 五、依赖关系

```
adapter.lua ← client.lua ← agent.lua ← channel.lua ← channel_view.lua
                                              ↑
                                    router.lua + scheduler.lua + task.lua

registry.lua ← init.lua
     ↓
channel.lua + chat.lua

store.lua ← channel.lua（只在保存时）
```

**无循环依赖**。所有箭头单向。

---

## 六、迁移策略

### 阶段一：抽模型（不改功能）

1. 抽出 `agent.lua`：从 bus.lua 提取 agent 数据结构
2. 抽出 `router.lua`：从 bus.lua 提取路由逻辑
3. 抽出 `scheduler.lua`：从 bus.lua 提取 main 队列 + agent 调度
4. bus.lua 改为调用这三个模块

**风险**：最低。纯重构，不改外部行为。
**验证**：现有频道功能不受影响。

### 阶段二：分离逻辑和 UI

5. bus.lua 拆成 `channel.lua`（逻辑）+ `channel_view.lua`（UI）
6. Channel 加事件系统，View 订阅事件
7. Chat 去掉 bus 模式，Agent 直接持有 Client

**风险**：中等。Chat bus 模式的删除需要仔细迁移。
**验证**：频道功能 + 独立 Chat 都正常。

### 阶段三：Registry + 多频道

8. 抽出 `registry.lua`
9. init.lua 瘦身
10. 支持多频道共存（#28）

**风险**：中等。init.lua 全局状态迁移需要逐步替换。
**验证**：同时开两个频道，各自独立运行。

### 阶段四：Task 层 + 协作原语

11. 加 `task.lua`
12. Scheduler 创建/管理 task
13. Channel view 展示 task 状态
14. RPC 加结构化协作原语（#22）

**风险**：低。新增功能，不改已有逻辑。

---

## 七、多频道和频道树的前置设计

### 多频道（#28）

Registry 维护 `channels` table，每个 Channel 独立：
- 独立的 agents、messages、tasks
- 独立的 view（可以同时显示多个频道 buffer）
- 共享 adapter 配置

Agent 可以跨频道吗？**暂时不**。每个频道有自己的 agent 实例（独立 client 进程）。跨频道共享 agent 是 P5 的事。

### 频道树（P4）

Channel 有 `parent` 和 `children` 字段：
- 子频道创建时传入 parent
- 子频道的消息可选上报父频道（通过 channel 事件机制）
- 父频道可以 inspect 子频道状态
- Agent 在子频道里 spawn 新子频道：通过 RPC 调 `channel:create_child()`

**关键**：Channel 逻辑层和 UI 层分离后，子频道可以 headless 运行（不开 buffer），只在需要时 attach view。

---

## 八、与现有修复的关系

| 已修 bug | 架构重设计后的处理 |
|----------|-------------------|
| #26 main 身份冲突 | Registry 统一管理 main client 归属，不再由 Chat.on_ready 竞争注册 |
| #27 output 泄漏 | Chat 不再有 bus 模式，Agent 直接持有 Client，on_update 路径唯一 |
| #31 agent 不回复兜底 | Scheduler 统一处理，self_posted 检测逻辑不变 |
| 500ms defer 竞态 | Registry 事件驱动，不需要 defer |
| main 队列超时 | Scheduler 内置超时，不在 channel 逻辑里 |
| 同名 agent 覆盖 | Agent 注册在 Channel.add_agent 里检查 |

---

## 九、改动量估算

| 阶段 | 新增/修改文件 | 估算行数 | 功能影响 |
|------|-------------|----------|----------|
| 一：抽模型 | agent.lua, router.lua, scheduler.lua + 改 bus.lua | ~300 新增, ~200 删减 | 零 |
| 二：分离 UI | channel.lua, channel_view.lua + 改 chat.lua | ~400 新增, ~300 删减 | 零 |
| 三：Registry | registry.lua + 改 init.lua | ~150 新增, ~100 删减 | 多频道 |
| 四：Task 层 | task.lua + 改 scheduler + view | ~200 新增 | 任务追踪 |

总计约 1050 行新增，600 行删减。净增 ~450 行，但模块从 5→12，平均每模块 ~140 行。

---

## 十、不做什么

1. **不做 workflow engine**：task 只是数据模型 + 状态机，不做 DAG/依赖/自动编排
2. **不做身份校验**（#24）：当前所有 agent 自己起的，伪造不是实际风险
3. **不做模型编排**（#25）：traits 标注等用户手动 @ 就行，不做自动派单
4. **不做结构化回复解析**：codex1 建议的 `STATUS: done` 解析，先不做
5. **不改 client.lua**：协议层稳定，不碰
6. **不改 adapter.lua**：配置层稳定，不碰

---

## 十一、建议实施顺序

```
阶段一（抽模型）→ 阶段二（分离 UI）→ 验证 → 阶段三（Registry）→ 阶段四（Task）
```

阶段一二可以一次做完（纯重构，不改功能）。阶段三四按需求优先级排。

关键约束：**每个阶段结束后，现有频道功能必须完全正常**。不允许"先拆完再联调"的大爆炸式重构。
