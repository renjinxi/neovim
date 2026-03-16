# 阶段二 Code Review

by claude2 | 2026-03-16

---

## 总体评价

Channel/View 分离干净。bus.lua 从 ~560 行降到 136 行纯 facade。Chat 的 bus 模式彻底移除，改为回调注入。task.lua 模型就位但未集成。事件驱动架构（on/emit）让逻辑层和 UI 层解耦正确。

**代码量变化**：
- bus.lua: ~560 → 136 行（-75%）
- 新增 channel.lua: 355 行（纯逻辑）
- 新增 channel_view.lua: 317 行（纯 UI）
- 新增 task.lua: 34 行（数据模型）
- chat.lua: bus 相关字段/逻辑全部移除

---

## 1. channel.lua — ✅ 通过（有 2 个问题）

### 1.1 事件系统 — 正确实现

`Channel:on(event, fn)` + `Channel:_emit(event, ...)` 实现简洁，ChannelView 通过构造函数订阅 `"message"` 和 `"state_changed"` 两个事件，方向单一。

### 1.2 回调解耦 — 关键改进

`add_agent()` L228-243 设置 Chat 回调（on_submit、on_agent_update、on_exit_notify）代替直接 bus 引用。**Chat 不再 require bus**，依赖方向正确。

### 1.3 消息存储 + 路由 — 正确搬入

`Channel:post()` 写日志 → emit "message" → router:route，逻辑和阶段一一致。

### 🟡 问题 1：channel.lua 未完全脱离 vim API

声明为"无 UI"层，但仍使用：
- `vim.fn.stdpath("config")` — L6
- `vim.fn.getcwd()` — L33
- `vim.fn.mkdir()` — L10, L74
- `vim.schedule()` — L112

其中 `vim.fn.stdpath` / `vim.fn.getcwd` / `vim.fn.mkdir` 是基础设施调用（文件系统、路径），不是 UI 操作（buffer/window/winbar）。`vim.schedule` 在 `notify_main_chat` 里用于线程安全，也不是 UI。

**结论**：当前定义"无 UI"= 无 buffer/window 操作，这些 vim.fn 调用可接受。但如果未来要做单元测试或脱离 nvim 运行，需要注入这些依赖。**不阻塞本次**。

### 🟡 问题 2：find_main_chat / notify_main_chat 仍 pcall(require, "acp.init")

L89-101、L104-118：从 bus.lua 原样搬过来的遗留耦合。Channel 直接依赖 init 模块查找 Chat 对象。

**本应**在阶段二通过事件机制替代（Phase 1 review 已指出）。比如 init.lua 在 open_chat 时主动把 Chat 引用注册到 Channel，而不是 Channel 反过来 pcall init。

**当前可接受**但错过了第二次清理机会。建议 M1 之前修。

---

## 2. channel_view.lua — ✅ 通过

### 2.1 事件订阅 — 正确

构造函数 L16-21：
```lua
channel:on("message", function(msg, gap) self:_render_message(msg, gap) end)
channel:on("state_changed", function() self:_refresh_winbar() end)
```

View 只监听，不主动写 Channel 状态。唯一的反向写入是 `_submit_input()` 调 `channel:post("你", text)`，这是用户输入的正常路径。

### 2.2 winbar 刷新 — 正确搬入

从 bus.lua 原样搬到 view，显示逻辑不变。queue_depth 通过 `channel.scheduler:main_queue_depth()` 读取。

### 2.3 BufWipeout / VimLeavePre — 合理

L92-108：View 在生命周期事件中调 `channel:_cleanup_agents()` 和 `channel:save_snapshot()`。虽然调了下划线方法，但 View 是 Channel 的唯一 UI 持有者，由它触发清理合理。

### 2.4 open / show / hide / close — 完整

UI 生命周期四件套齐全，和 Chat 的模式一致。`show()` 正确恢复 winbar 和 autoresize。

---

## 3. task.lua — ✅ 通过（有 1 个说明）

### 3.1 数据模型 — 最小可用

字段：id、title、owner、requester、status（queued/running/done/failed）、artifacts、时间戳。
方法：start()、done(artifacts)、fail(reason)。

符合裁决要求："先把数据模型放进去，M1 再集成"。

### 📝 说明：尚未集成

- agent.lua 已加 `current_task = nil` 字段
- scheduler.lua 的 `push_to_agent` 没有创建 Task 对象
- Channel 没有 tasks 列表
- ChannelView 没有 task 状态显示

**预期行为**：M1 阶段集成，当前只是占位。不影响功能。

---

## 4. chat.lua — ✅ 通过（关键改进）

### 4.1 bus 模式彻底移除

对比旧代码，以下字段/逻辑已删除：
- ❌ `self.bus`
- ❌ `self.bus_agent_name`
- ❌ `_submit_input` 里的 `if self.bus then` 分支
- ❌ `_on_update` 里的 `if self.bus then` 分支

替换为三个回调：
- ✅ `on_submit` — 输入框提交走频道路由
- ✅ `on_agent_update` — session/update 转发
- ✅ `on_exit_notify` — 进程退出通知

### 4.2 回调调用时机 — 正确

- `_submit_input` L292-295：先检查 on_submit，有则走频道路由，否则直接 send
- `_on_update` L355-357：在 Chat 自身处理完 update 后，转发给频道
- `on_exit` L232-234：在 vim.schedule 内调用，线程安全

### 4.3 on_ready 回调 — 正确

L261-263：client 启动成功后触发 on_ready(self.client)。Channel:add_agent 在 on_ready 里注册 client 到 agent，触发上线消息。

### 4.4 open_headless — 正确

L140-208：headless 模式只创建 buffer 不创建 window。和 open() 共享 keymap/autocmd 设置。open/open_headless 代码有重复（buffer 创建、keymap、autocmd），但阶段二不是解决 DRY 的时机。

---

## 5. bus.lua — ✅ 通过（纯 facade）

### 5.1 __index 代理 — 正确但需注意

L8-24：优先 Bus 自身方法 → view 字段（win/buf/input_win/input_buf）→ channel 字段（agents/messages/scheduler 等）。

**风险**：`init.lua` L57、L122 通过 `active_bus.agents` 直接访问 channel 内部数据，依赖 __index 代理透传。这能工作，但如果 Channel 的字段名和 Bus/View 冲突，会产生隐蔽 bug。

**当前安全**：目前无命名冲突。但建议 `init.lua` 改用 `active_bus:list_agents()` 等公有方法而不是直接字段访问。

### 5.2 方法委托 — 完整

所有公有方法（post、add_agent、read、list_agents、save_snapshot、restore_from_snapshot、open_agent_buf）正确委托。

### 5.3 _refresh_winbar 兼容 — 合理

L75-77：`Bus:_refresh_winbar()` 委托给 `view:_refresh_winbar()`。这是为了兼容 scheduler.lua L67 和 init.lua L221 的调用。不优雅但实用。

**建议**：scheduler 应该只调 `bus:state_changed()`，不应直接调 `_refresh_winbar`。检查：

- scheduler.lua L67: `main_chat:_refresh_winbar()` — 这是调 Chat 的方法，不是 bus，OK
- scheduler.lua L93: `main_chat:_refresh_winbar()` — 同上，OK
- init.lua L221: `active_bus:_refresh_winbar()` — 通过 facade 调 view，应改为 `active_bus:state_changed()`

---

## 6. init.lua — ✅ 通过（有 1 个问题）

### 6.1 同步注册 — 修复 defer 竞态

L235-246：`open_bus` 里直接同步检查已有 Chat client 并注册，不再用 500ms defer_fn。正确。

### 6.2 on_ready 防重复注册 — 修复 #26

L217：`if not main.client or not main.client.alive then` — 只在 main 无活跃 client 时注册。正确。

### 🟡 问题：init.lua 直接访问 bus.agents 内部字段

L57：`for name, agent in pairs(active_bus.agents) do`
L122：`for name, agent in pairs(active_bus.agents) do`
L163-168：`active_bus.agents[agent_name]`、`agent.client`、`agent.client.session_id`
L235：`active_bus.agents["main"]`

这些通过 __index 代理透传到 channel.agents。**能工作但脆弱**。

建议：对外只暴露 `list_agents()`（已有）和 `get_agent(name)`（需新增）。但不阻塞本次。

---

## 7. scheduler.lua — ✅ 适配正确

### 7.1 Phase 1 review 的 🔴 已修

L227-231：错误通知改为 `bus:post("系统", "@" .. sender .. " " .. err_msg)`，不再直接调 `router._send_to`。

### 7.2 接口对齐

- `bus:state_changed()` — 替代直接 `_refresh_winbar()`
- `bus:find_main_chat()` — 替代内部查找
- `bus:notify_main_chat()` — 替代内部通知
- `bus:session_write()` — 替代本地重复定义
- `bus:_extract_text()` — 仍通过 facade 调用

### 7.3 session_write 重复 — 已修

Phase 1 指出的 DRY 问题，scheduler 现在用 `bus:session_write()`，不再有本地副本。

---

## 8. 依赖方向

```
init.lua ─── require ──→ bus.lua ──→ channel.lua ──→ agent.lua
                                 │                ──→ router.lua
                                 │                ──→ scheduler.lua
                                 ├──→ channel_view.lua (require channel 类型)
                                 └──→ task.lua (agent.lua 引用)

channel.lua ── pcall ──→ init.lua  (遗留，应改为注入)
scheduler.lua ── 运行时 ──→ bus (构造函数注入)
router.lua ── 运行时 ──→ bus (构造函数注入)
chat.lua ── 无 bus 依赖 ── (回调注入)
```

**无新增循环依赖**。channel → init 的 pcall 是遗留，Phase 1 就存在。
Chat 对 bus 的依赖彻底解除，是本次最大架构改进。

---

## 9. 对外 API 检查

| API | 状态 |
|-----|------|
| Bus:post(from, content, opts) | ✅ 不变 |
| Bus:read(last_n) | ✅ 不变 |
| Bus:list_agents() | ✅ 不变 |
| Bus:add_agent(name, adapter_name, opts) | ✅ 不变 |
| Bus:open_agent_buf(name) | ✅ 不变 |
| Bus:hide() / Bus:show() | ✅ 不变 |
| Bus:close() | ✅ 不变 |
| Bus:save_snapshot() | ✅ 不变 |
| Bus:restore_from_snapshot(snapshot) | ✅ 不变 |
| Bus.agents (字段访问) | ✅ __index 代理 |
| Bus.win / buf / input_win / input_buf | ✅ __index 代理 |
| Chat.on_ready / on_submit / on_agent_update / on_exit_notify | ✅ 新增回调 |

RPC 接口（init.lua 的 bus_post/bus_read/bus_agents/bus_send）全部不变。

---

## 10. Phase 1 遗留问题追踪

| Phase 1 问题 | 状态 |
|-------------|------|
| 🔴 scheduler L272 调 router._send_to | ✅ 已修，改为 bus:post |
| 🟡 depth 传递不生效 | ⏳ 未修，Phase 1 说低风险 |
| 🟡 session_write 重复 | ✅ 已修，scheduler 改用 bus:session_write |
| 🟡 _schedule_drain 500ms 轮询 | ⏳ 未修，不影响功能 |
| 🟡 pcall(require, "acp.init") 耦合 | ⏳ 未修，错过第二次清理机会 |

---

## 总结

| 级别 | 数量 | 说明 |
|------|------|------|
| 🔴 要修 | 0 | 无阻塞问题 |
| 🟡 建议 | 3 | channel vim.fn 依赖、pcall init 耦合（遗留）、init.lua 直接字段访问 |
| 📝 说明 | 1 | task.lua 未集成（预期行为，M1 做） |
| ✅ 改进 | 4 | Chat bus 模式移除、事件驱动解耦、facade 统一代理、session_write DRY 修复 |

**结论**：阶段二通过。Channel/View 分离正确，Chat 解耦彻底，facade 保持 API 兼容。可以进入 M1 阶段。
