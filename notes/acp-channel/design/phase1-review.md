# 阶段一 Code Review

by claude2 | 2026-03-16

---

## 总体评价

抽取干净，bus.lua 从 ~750 行降到 ~560 行。三个新模块职责边界清晰。对外 API 不变。同时修复了之前 review 的两个问题（on_update monkey-patch、autocmd 叠加）。

---

## 1. agent.lua — ✅ 通过

**完整性**：所有 agent 字段集中定义，两个构造函数（new_spawned/new_local）覆盖两种 kind。

**状态操作集中**：
- `is_alive()` — 替代散落的 `agent.client and agent.client.alive`
- `reset_stream()` — 替代手动三行重置
- `sync_chat_streaming()` — 把 Chat streaming 同步封装起来
- `cleanup()` — 集中清理，区分有 chat 和无 chat 的情况

**一个小问题**：`sync_chat_streaming` 调了 `self.chat:_refresh_winbar()`，这是 Agent 穿透到 Chat 的私有方法。当前可接受（比之前散落在 bus.lua 十几处好多了），阶段二 Chat 去 bus 模式时应该一并清理。

---

## 2. router.lua — ✅ 通过

**路由逻辑正确抽出**：route + _send_to，和之前 bus.lua 的逻辑一致。

**depth 限制**：max_depth=5，正确实现。但有一个设计细节：当前 route() 的 depth 参数没有被调用者传递。

看调用链：
- `bus:post → router:route(content, from)` — depth 默认 0
- `scheduler:push_to_agent` 的兜底回复调 `bus:post(name, ...)` → `router:route` — depth 又从 0 开始

**这意味着 depth 限制实际上不生效**。每次经过 bus:post 都会重置 depth=0。要真正防循环，depth 需要随消息传递（比如 post 的 opts 里带 depth），或者改用时间窗口内消息计数。

**当前风险**：低。裁决里说了循环路由当前任务模式下不太会出现，depth 是预防机制。但既然写了就应该能工作。

**建议**：bus:post 的 opts 加 `depth` 字段，传给 router:route。一行改动。

---

## 3. scheduler.lua — ✅ 通过（有 2 个问题）

### 3.1 背压 — 正确实现
`MAX_MAIN_QUEUE=10`，`_enqueue_main` 检查超限后丢弃 + post 通知。符合裁决要求。

### 3.2 on_chunk 替代 monkey-patch — 关键改进
L89 用 `client:prompt(content, on_done, on_chunk)` 的第三参数收集输出，不再劫持 `client.on_update`。**这修复了之前 review 的 BUG-1**（_push_to_main 期间主 Chat streaming 状态未同步）。

### 3.3 main Chat streaming 同步 — 正确
L73-77 在 push_to_main 开始时同步 `main_chat.streaming = true`，L101-103 完成时恢复。之前 review 指出的漏洞已修。

### 3.4 兜底回复 + self_posted 检测 — 新增，逻辑正确
L238-256：agent prompt 完成后，检查 agent 是否在 prompt 期间自行 post 过消息。如果没有，自动把 stream_buf 摘要 post 到频道。这是 #31 的修复。

`_extract_summary` 取最后一段或截断 200 字，合理。

### 🔴 问题 1：_send_to 私有方法跨模块调用

**L272**：
```lua
bus.router:_send_to(sender, notify_msg, "系统")
```

Scheduler 直接调 Router 的下划线方法。应该走 `bus:post("系统", notify_msg)` 让路由自动处理，或者 Router 暴露一个公有方法。

当前代码的意图是"通知发送者出错了"，直接 post 到频道会让所有人看到错误消息后自动路由给发送者（因为内容里有 @sender）。所以**改成 bus:post 就行**，不需要直接调 _send_to。

### 🟡 问题 2：_find_main_chat / _notify_main_chat 仍然 pcall(require, "acp.init")

**L153, L168**：这是阶段一之前就存在的问题，从 bus.lua 原样搬过来。不是新引入的循环依赖，但错过了清理机会。

阶段二分离 Channel/View 时应该通过事件机制替代。当前可接受。

### 🟡 问题 3：_schedule_drain 的 500ms 定时器可能堆积

**L136-148**：main Chat 直接对话时，消息入队 + 启动 500ms drain 定时器。如果 main Chat 对话持续很久（比如 5 分钟），_schedule_drain 会每 500ms 递归调用自己一次（L143），产生 600 次 defer_fn 调用。

虽然有 `_drain_pending` 防重入，但每次 defer_fn 触发后立即设 false 再设 true 重新调度（L139-143），**实际是安全的**（同一时间只有一个 pending）。只是 500ms 轮询不够优雅。

**建议**：改用更长的间隔（2s），或在 main Chat streaming 结束时主动触发 drain（事件驱动）。但不阻塞本次 review。

---

## 4. bus.lua — ✅ 瘦身干净

### 已正确抽走的逻辑
- ✅ agent 数据模型 → agent.lua
- ✅ @mention 路由 → router.lua
- ✅ main 队列 + agent prompt 调度 → scheduler.lua
- ✅ _cleanup_agents 改用 agent:cleanup()
- ✅ list_agents 改用 agent:is_alive()
- ✅ winbar queue 深度改用 scheduler:main_queue_depth()
- ✅ 同名 agent 防御（L289-292）
- ✅ _setup_input_autoresize 用 augroup 防重复注册（修复了之前 WARN-1）

### 仍保留在 bus.lua 的逻辑（合理）
- UI：buffer/window/winbar/input/scroll — 这些是阶段二的事
- 消息存储 + 渲染 — 阶段二拆 channel/channel_view 时处理
- _on_agent_update — 更新 agent 状态 + 刷 winbar，放 bus 合理
- add_agent — 创建 Chat + Agent，是编排逻辑，放 bus 合理
- _extract_text — 工具函数，放哪都行

### session_write 重复定义
bus.lua L21-27 和 scheduler.lua L14-20 有完全相同的 `session_write` 函数。应该提取到共享位置（比如 agent.lua 或一个 util）。不影响功能但违反 DRY。

---

## 5. 依赖方向

```
bus.lua ──require──→ agent.lua     (无 require)
bus.lua ──require──→ router.lua    (无 require，运行时引用 bus)
bus.lua ──require──→ scheduler.lua (无 require，运行时引用 bus + pcall init)
```

**无新增循环依赖**。scheduler → init 的 pcall 是遗留问题，不是新引入的。

router 和 scheduler 通过构造函数接收 bus 引用，不通过 require。方向正确。

---

## 6. 对外 API 检查

| API | 状态 |
|-----|------|
| Bus:post(from, content, opts) | ✅ 不变 |
| Bus:read(last_n) | ✅ 不变 |
| Bus:list_agents() | ✅ 不变（字段兼容） |
| Bus:add_agent(name, adapter_name, opts) | ✅ 不变（加了同名防御，行为更好） |
| Bus:open_agent_buf(name) | ✅ 不变 |
| Bus:hide() / Bus:show() | ✅ 不变 |
| Bus:close() | ✅ 不变 |
| Bus:save_snapshot() | ✅ 不变 |
| Bus:restore_from_snapshot(snapshot) | ✅ 不变 |

---

## 总结

| 级别 | 数量 | 说明 |
|------|------|------|
| 🔴 要修 | 1 | scheduler L272 直接调 router._send_to，改成 bus:post |
| 🟡 建议 | 3 | depth 传递不生效、session_write 重复、_schedule_drain 轮询 |
| ✅ 改进 | 3 | on_chunk 修复 BUG-1、autocmd augroup 修复 WARN-1、main streaming 同步 |

**结论**：阶段一通过。修掉 🔴 后可以跑验证流程，然后进阶段二。
