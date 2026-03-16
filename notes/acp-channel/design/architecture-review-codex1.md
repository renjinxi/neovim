# ACP 架构评审（Codex1）

by codex1 | 2026-03-16

---

## 结论

当前 ACP 架构在 M0 阶段是可工作的，但已经明显进入“补丁继续能跑，继续长会越来越难改”的状态。

核心问题不是某个函数写得乱，而是三个结构性事实：

1. `Bus` 既是领域层，又是状态仓库，又是 UI 控制器。
2. `Chat` 既负责渲染，又直接持有 `Client`，还会反向修改 `Bus` 状态。
3. `init.lua` 用全局单例把生命周期钉死，导致多频道、多主会话、子频道都很难自然扩展。

所以 #29 应该按“重新梳理边界”处理，而不是继续围绕 `bus.lua` 打补丁。

---

## 1. 模块间耦合度评估

### 1.1 Chat ↔ Bus ↔ Client 是三角双向依赖

当前关系不是清晰的分层调用，而是三角互相感知：

- `Chat` 创建并持有 `Client`
- `Chat:_on_update()` 在处理自己 UI 的同时调用 `bus:_on_agent_update()`
- `Chat:on_exit` 直接改 `bus.agents[...]`
- `Bus:add_agent()` 创建 `Chat`，再把 `chat.bus = self`
- `Bus:send_to_agent()` 直接调用 `agent.chat:_append_role()`、改 `agent.chat.streaming`
- `Bus:_push_to_main()` 和 `Bus:_notify_main_chat()` 反向去 `require("acp.init")` 找 Chat
- `init.lua` 再维护 `active_chats` / `active_bus` 全局注册表

这意味着：

- 状态变更路径很多，来源不唯一
- 任何一个模块都很难被单独替换或测试
- 修一个场景时，很容易误伤另一个场景

这是当前 #26、#27 的根源，不是单点 bug。

### 1.2 `Bus` 过胖，已经不是“频道对象”，而是系统核心

`bus.lua` 当前承担了至少六类职责：

1. 频道 UI 创建、hide/show、winbar、输入框 autoresize
2. 消息存储与渲染
3. agent registry
4. 路由和主队列调度
5. prompt 生命周期管理
6. 持久化入口和恢复 orchestration

这会带来两个直接后果：

- 任何新增能力都自然堆到 `Bus`
- 很多逻辑只能以“改字段 + 刷 winbar + 顺手改 chat”的方式演化

如果继续这样发展，后面 task 层、inspect、子频道都会继续堆到 `Bus`，最后会变成一个不可拆的大对象。

### 1.3 `Client` 边界相对清楚，但缺“会话层”缓冲

`client.lua` 的职责目前最清晰：进程、ACP 协议、反向能力、I/O 生命周期。问题不在 `Client` 本身，而在它被 `Chat` 直接拥有。

现在系统里没有一个“AgentSession / ConversationSession”层来包住：

- `Client`
- prompt 生命周期
- agent 状态
- task 上下文
- telemetry

因此这些都被分散到了 `Bus.agents[name]`、`Chat.streaming`、`Client.alive` 之间。

### 1.4 `init.lua` 是事实上的全局 service locator

`init.lua` 暴露：

- `active_bus`
- `active_chats`
- `get_bus()`
- `_active_chats()`

然后 `Bus` 会反向 `require("acp.init")` 查找主 chat。

这是一种典型的隐藏耦合：

- 依赖不是通过参数或接口注入，而是 runtime lookup
- 单元测试困难
- 多实例天然困难

这类耦合在 M0 很方便，但一旦要支持多 bus、多 main、多视图，它会成为最大的结构阻力。

---

## 2. 扩展性评估：多频道实例、子频道

### 2.1 当前架构不适合多频道实例

结论很明确：当前代码只能稳定支持单频道。

根本原因有三层：

1. `init.lua` 的 `active_bus` 是单例
2. 大量逻辑默认“main 只有一个”
3. `Bus` 内部通过 `require("acp.init")` 去查全局 chat，而不是查自己所属上下文

即使把 `active_bus` 改成 `active_buses`，也不够，因为下面这些假设仍然存在：

- `main` 是全局身份，不是频道内身份
- `bus_post()` / `bus_send()` RPC 没有 channel 维度
- `open_native_cli()` 默认在“当前唯一 bus”里找 agent
- `store.restore` 也是恢复一个当前频道，而不是恢复到某个 session registry

所以 #28 不是“把单例改 map”那么简单，而是要先改上下文模型。

### 2.2 子频道在当前架构下几乎没有自然落点

子频道本质需要：

- 父子 channel identity
- channel scope 内独立 agent 集合
- 跨频道消息桥
- 父频道只看摘要，子频道内部保留详细事件

但当前 `Bus` 同时承担了“消息流 + 状态面 + UI 面板”。这意味着一旦加子频道，会马上遇到：

- 子频道是一个新的 `Bus` 对象，还是当前 `Bus` 的子结构？
- `main` 是父频道 main 还是全局 main？
- `bus_post` 发到哪个 channel？
- artifact 和 snapshot 怎么归属？

所以在没有先拆出“ChannelSession”和“ChannelView”之前，子频道不适合直接做。

### 2.3 真正缺的是上下文注册表

如果后续要支持多频道/子频道，我建议先引入一个 registry 层，而不是让 `init.lua` 继续直接持有对象：

```lua
SessionRegistry = {
  channels = { [channel_id] = ChannelSession },
  chats = { [chat_id] = ChatView },
  main_bindings = { [channel_id] = agent_session_id },
}
```

这样：

- RPC 可以显式传 `channel_id`
- UI 可以挂接到某个 channel
- 一个 agent 身份可以是“频道内 main”，而不是全局 main

没有这个 registry，多频道会一直是表面支持、深层冲突。

---

## 3. 状态管理评估

### 3.1 当前状态分散在三层对象里，没有单一事实源

同一个 agent 的状态，当前可能同时出现在：

- `Bus.agents[name].status`
- `Bus.agents[name].streaming`
- `Bus.agents[name].activity`
- `Chat.streaming`
- `Client.alive`
- `Client.session_id`

这不是“冗余缓存”，而是多个对象都在直接写状态。于是系统要靠开发者约定这些字段什么时候同步。

这会导致两个问题：

1. 状态漂移
一个字段变了，另一个没跟上。

2. 修复成本高
每加一个状态切换，都要想到 bus/chat/client 三处。

### 3.2 消息存储和消息展示没有分离

`Bus.messages` 既是历史消息数据，又立刻驱动 `_render_message()`，同时还会写日志文件。

这意味着消息一进入系统，就立刻绑定了三种副作用：

- 内存存储
- buffer 渲染
- 落盘

短期简单，长期会很难做：

- inspect 视图
- task board
- 过滤视图
- 按 agent 查询
- 跨频道聚合

因为消息不是先进入 store，再由不同 view 订阅，而是 `Bus:post()` 一次性把所有事都做了。

### 3.3 UI 状态和领域状态混在一起

例如：

- `Bus.win` / `Bus.input_win` / `Bus.buf`
- `Chat.win` / `Chat.input_win`
- `Bus.agents[name].status`
- `Chat.streaming`

这些状态类型完全不同，但现在混在同一个对象生命周期里。

建议至少拆成三类：

1. 领域状态
channel、agent、task、message

2. 运行时状态
client 连接、队列、超时、pending request

3. 视图状态
buffer、window、cursor、visible

现在 ACP 最缺的不是更多字段，而是状态分类。

### 3.4 恢复机制目前恢复的是“历史画面”，不是“工作状态”

`store.lua` + `restore_from_snapshot()` 当前保存的是：

- channel_id
- agents
- history

恢复时回填历史消息，然后重新 `add_agent()`。

这更像“重建现场 UI”，不是恢复运行时。

所以建议在设计上把恢复明确拆成两种：

- `restore_view`: 恢复消息和面板
- `resume_work`: 恢复 agent/task 上下文

当前架构把两者混在一起，容易让用户误解“频道恢复后就能继续原来的协作状态”。

---

## 4. #21-#25 哪些现在该做

我的判断是：#21、#22、#23 现在该做，而且应该作为 M1 的架构骨架；#24 需要做最小版本；#25 应晚一点做，不该现在展开太多。

### 4.1 现在就该做：#21 轻量 task 层

这是最关键的架构切口。

原因：

- 它能把“频道消息流”和“任务状态”分开
- 它是 inspect、artifact、恢复语义化的前提
- 它能减少 `Bus` 继续膨胀

建议不要一开始做复杂 workflow，只要最小 task store：

```lua
Task = {
  id,
  title,
  owner,
  requester,
  status,      -- queued/running/blocked/done/failed
  assignees,
  artifacts,
  summary,
  created_at,
  updated_at,
}
```

第一阶段甚至可以允许 task 仍然由自然语言触发，只是系统内部要有对象化表示。

### 4.2 现在就该做：#22 结构化协作原语

如果不做这一层，task 还是会退化回“文本约定”。

建议先做最少四个动作：

- `assign`
- `done`
- `blocked`
- `artifact`

这些动作不一定一开始就开放完整 RPC；甚至可以先由 bus 在本地消费标准消息头。但系统内部必须先有结构化事件。

否则 #21 做完也只是多了个空 store。

### 4.3 现在就该做：#23 可观测性面板

这不是“体验锦上添花”，而是解耦频道语义的必要步骤。

原因：

- 频道不该继续兼任日志、状态面、任务面
- 结构化状态出来后，必须有地方展示

建议第一版做最简单的 `:Acp inspect`：

- 当前 channel
- 各 agent 状态
- main 队列长度
- 最近 task
- 最近错误
- 最近 artifact

不用一开始做很漂亮，但必须把状态面从频道里拿出来。

### 4.4 现在做最小版本：#24 身份校验 + 背压

这项我建议拆开看。

身份校验：

- 完整 token/nonce 体系可以后做
- 但现在至少要让 RPC 带 `channel_id`
- 并且只接受已注册 agent 名字发言

背压：

- 现在就该做最小版本
- 因为 `main` 队列、agent prompt、自动兜底回复已经开始形成真实负载

最小背压建议：

- 每个 agent 最大 pending 数
- `main` 队列最大长度
- 超出直接 `busy`
- prompt 超时后自动失败

不需要一开始做复杂调度器，但必须停止“无限堆消息”。

### 4.5 可以晚一点：#25 模型能力差异化编排

这项方向没问题，但不是当前最急。

原因：

- 现在系统连 task / state / inspect 都还没立住
- 过早做 traits 调度，会把问题复杂化

我建议 M1 只做静态 metadata，不做自动编排：

```lua
adapter.traits = {
  strengths = {"review", "implementation"},
  latency = "medium",
  tooling = {"fs", "terminal"},
}
```

先把元数据挂起来，真正的 planner-based dispatch 放到 task 层稳定之后。

---

## 建议的 M1 重构方向

### 目标边界

我建议把现有结构拆成五层：

1. `Client`
只管 ACP 进程和协议。

2. `AgentSession`
包住一个 client 的运行时状态、prompt 生命周期、telemetry。

3. `ChannelStore`
存 messages / agents / tasks / artifacts，是单一事实源。

4. `ChannelController`
负责路由、分配、队列、协作原语处理。

5. `ChatView` / `BusView` / `InspectView`
只订阅 store 并渲染，不直接拥有业务状态。

### 推荐调用方向

应尽量变成单向：

`View -> Controller -> Store/Session -> Client`

而不是现在这样：

`Bus -> Chat -> Client -> Chat -> Bus -> init -> Chat`

### 迁移顺序

我建议按下面顺序迁移，而不是一次性重写：

1. 先引入 `ChannelStore`
把 `messages`、`agents`、`tasks` 抽出来。

2. 再把 `Bus:post()` 改成“写 store + 由 view 订阅渲染”

3. 再引入 `AgentSession`
把 `Bus.agents[name].client/chat/status/...` 这种松散表收束。

4. 最后把 `init.lua` 单例变成 registry

这样既能保留现有 UI，又能逐步去掉隐藏耦合。

---

## 我建议本轮不要再做的事

在边界没重画之前，我不建议继续往 `bus.lua` 里加这些：

- 子频道
- 自动模型派单
- 更复杂的频道命令
- 更多“补一处状态同步”的逻辑

因为这些都会进一步固化当前耦合。

---

## 最终判断

如果只问一句话：当前架构能不能继续支撑功能增长？

答案是：

- 修 bug 和补少量能力，还能撑一段
- 但想上多频道、子频道、task 层、inspect，就必须先做 M1 边界重构

所以 #29 不应该被理解为“review 一下现状”，而应该被理解为：

**确认 M1 的首要目标，是把 ACP 从单对象驱动的 UI 系统，重构成 store/session/controller/view 分层的协作系统。**
