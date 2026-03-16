# 阶段三 Code Review

by claude2 | 2026-03-16

---

## 总体评价

Registry 抽取正确，init.lua 从状态持有者降为纯命令路由。channel → init 循环依赖通过回调注入消除。多频道支持在 RPC 层已就绪（channel_id 参数），Picker 支持多频道列表和切换。

**代码量变化**：
- 新增 registry.lua: 141 行
- init.lua: 去掉 active_chats/active_bus 局部变量，全部走 reg()
- channel.lua: find_main_chat/notify_main_chat 改为回调委托
- rpc.lua: 所有 RPC 函数新增 channel_id 可选参数

---

## 1. registry.lua — ✅ 通过（有 1 个问题）

### 1.1 单例模式 — 正确

`Registry.get()` 返回模块级 `_instance`。init.lua 通过 `reg()` 延迟获取，避免 require 时序问题。

### 1.2 回调注入消除循环依赖 — 关键改进

L28-33：`create_channel` 注入 `_find_main_chat_fn` 和 `_notify_main_chat_fn`，Channel 不再 pcall(require, "acp.init")。**Phase 2 review 的 🟡 问题 2 已修**。

### 1.3 find_main_chat / notify_main_chat — 正确

L64-87：Registry 持有所有 chats，自然能匹配 channel.agents["main"].client == chat.client。逻辑和原来一致，位置更合理。

### 1.4 close_channel — 正确

L103-115：关闭后自动切到 `next(self.channels)`。边界：如果只有一个频道，next 返回 nil，active_channel_id 变 nil。正确。

### 🟡 问题 1：create_channel 访问 bus._channel 内部字段

L25：`local channel = bus._channel` — Registry 穿透 Bus facade 直接拿 Channel 实例来注入回调。

这打破了 facade 的封装。如果 Bus 内部重命名 _channel 字段，Registry 就挂了。

**建议**：Bus 暴露一个方法 `Bus:inject_channel_callbacks(find_fn, notify_fn)`，内部转发给 _channel。一行改动。但不阻塞。

---

## 2. init.lua — ✅ 通过（瘦身干净）

### 2.1 状态全部迁入 Registry

对比 Phase 2 版本：
- ❌ `local active_chats = {}`
- ❌ `local active_bus = nil`
- ✅ 全部改为 `reg():get_active_channel()` / `r.chats` / `r:create_chat()`

init.lua 现在是纯命令分发层，不持有任何状态。正确。

### 2.2 open_chat on_ready — 正确

L219-231：通过 `r:get_active_channel()` 获取活跃频道，不再依赖闭包捕获的 active_bus 变量。多频道场景下，on_ready 时获取的是当时的活跃频道，语义正确。

### 2.3 show_picker 多频道 — 正确

L115-147：遍历 `r.channels` 显示所有频道，标记 active（`*`）。选中时设 `r.active_channel_id = channel_id`，实现频道切换。

### 2.4 open_bus — 正确

L237-257：只在 `get_active_channel()` 返回 nil 时创建新频道。已有频道时直接 add_agent。符合当前 `:Acp bus` 的语义。

**潜在问题**：`:Acp bus` 子命令 L24-33 在有活跃频道时只 toggle 显示，不会 add_agent。只有首次才走 `M.open_bus` 并 add_agent。这是否符合用户预期？如果用户想在已有频道里加 agent，需要其他路径（RPC 或直接输入 @mention）。当前行为和 Phase 2 一致，不是新问题。

---

## 3. channel.lua — ✅ 通过（循环依赖已消除）

### 3.1 回调字段 — 正确

L42-43：
```lua
_find_main_chat_fn = nil,  -- 由 registry 注入
_notify_main_chat_fn = nil, -- 由 registry 注入
```

L91-103：
```lua
function Channel:find_main_chat()
    if self._find_main_chat_fn then
        return self._find_main_chat_fn()
    end
    return nil
end
```

不再有 `pcall(require, "acp.init")`。方法签名不变，scheduler 和其他调用方无感知。

### 3.2 其余部分 — 无变化

与 Phase 2 相同，事件系统、消息存储、路由、调度不受影响。

---

## 4. rpc.lua — ✅ 通过（有 1 个问题）

### 4.1 channel_id 参数 — 正确添加

所有 RPC 函数（bus_post、bus_read、bus_send、bus_agents）新增可选 `channel_id` 参数，透传到 `acp.bus_post(from, text, channel_id)` → `reg():get_active_channel(channel_id)`。

不传 channel_id 时走 active，**向后完全兼容**。

### 4.2 新增 list_channels — 正确

L173-175：返回所有频道 ID 列表。外部调用方可先 list 再指定 channel_id 操作。

### 🟡 问题 1：bus_stop 直接操作 registry 内部

L156-164：
```lua
local registry = require("acp.registry").get()
local channel_id = args.channel_id or registry.active_channel_id
if channel_id then
    registry.channels[channel_id] = nil
    if registry.active_channel_id == channel_id then
        registry.active_channel_id = next(registry.channels)
    end
end
```

这段代码和 `Registry:close_channel()` 逻辑完全重复。应该直接调 `registry:close_channel(channel_id)` 而不是手动操作内部字段。

当前代码的问题：bus:close() 在前，registry 清理在后。如果 bus:close() 抛异常（pcall 捕获），仍然会从 registry 移除。而 `Registry:close_channel()` 也是这个行为（pcall 后 nil 掉），所以**功能等价但违反 DRY**。

**建议**：改为一行 `registry:close_channel(args.channel_id)`。

---

## 5. 依赖方向

```
init.lua ─── require ──→ registry.lua ──→ bus.lua ──→ channel.lua
                                      │            ──→ channel_view.lua
                                      ├──→ chat.lua
                                      └── 运行时注入 ──→ channel (回调)

rpc.lua ─── require ──→ acp (init.lua)
scheduler.lua ── 运行时 ──→ bus (构造函数注入)
router.lua ── 运行时 ──→ bus (构造函数注入)
```

**循环依赖已消除**：channel.lua 不再 require/pcall init.lua。通过 registry 注入回调，方向单一。

---

## 6. 多频道是否真正可用

| 场景 | 状态 |
|------|------|
| 创建多个频道 | ✅ `r:create_channel()` 每次生成新 channel_id |
| 频道切换 | ✅ Picker 选中频道时设 active_channel_id |
| RPC 指定频道 | ✅ 所有 RPC 支持 channel_id 参数 |
| 同时显示多频道 | ⚠ UI 层未处理多窗口并存 |
| main agent 归属 | ⚠ 每个频道有自己的 main，但 Chat on_ready 只注册到 active 频道 |
| 快照恢复 | ✅ select_bus 关闭当前频道再恢复 |

### ⚠ main agent 多频道归属问题

`open_chat` L219-231：Chat 的 on_ready 只看 `r:get_active_channel()`。如果用户：
1. 创建频道 A（active）
2. 创建频道 B（active 切到 B）
3. 打开 Chat → on_ready 注册 client 到频道 B 的 main

频道 A 的 main 永远没有 client。这是设计权衡还是遗漏？

**当前可接受**：M1 阶段只用一个频道。M2 再处理多频道 main 共享/隔离。

---

## 7. API 兼容性

### init.lua 对外 API

| API | 状态 |
|-----|------|
| M.bus_post(from, content) | ✅ 兼容，新增可选 channel_id |
| M.bus_read(last_n) | ✅ 兼容，新增可选 channel_id |
| M.bus_agents() | ✅ 兼容，新增可选 channel_id |
| M.bus_send(agent_name, text) | ✅ 兼容，新增可选 channel_id |
| M.get_bus() | ✅ 兼容，新增可选 channel_id |
| M.list_channels() | ✅ 新增 |
| M.stop_all() | ✅ 不变 |
| M._active_chats() | ❌ 已删除 |

### _active_chats 删除影响

Phase 2 的 channel.lua 通过 `pcall(require, "acp.init")` 调 `init._active_chats()`。Phase 3 已改为回调注入，所以**删除是安全的**。无外部调用方。

### rpc.lua 对外 API

| API | 状态 |
|-----|------|
| bus_open(raw) | ✅ 不变 |
| bus_post(raw) | ✅ 兼容，args 新增可选 channel_id |
| bus_post_file(from, path) | ✅ 不变（不支持 channel_id，合理） |
| bus_read(raw) | ✅ 兼容 |
| bus_send(raw) | ✅ 兼容 |
| bus_agents(raw) | ✅ 兼容 |
| bus_stop(raw) | ✅ 兼容，新增可选 channel_id |
| list_channels(_) | ✅ 新增 |
| list_adapters(_) | ✅ 不变 |

---

## 8. Phase 2 遗留问题追踪

| Phase 2 问题 | 状态 |
|-------------|------|
| 🟡 pcall(require, "acp.init") 耦合 | ✅ 已修，改为 registry 回调注入 |
| 🟡 init.lua 直接字段访问 bus.agents | ⏳ 仍存在（L61, L171, L221, L244） |
| 🟡 init.lua L221 _refresh_winbar | ⏳ 仍存在（L228, L250） |
| 🟡 channel vim.fn 依赖 | ⏳ 不影响功能 |
| 📝 task.lua 未集成 | ⏳ M1 做 |

---

## 总结

| 级别 | 数量 | 说明 |
|------|------|------|
| 🔴 要修 | 0 | 无阻塞问题 |
| 🟡 建议 | 2 | registry 穿透 bus._channel、rpc.bus_stop 重复 close 逻辑 |
| ⚠ 设计限制 | 1 | 多频道 main agent 归属（M2 范围） |
| ✅ 改进 | 3 | 循环依赖消除、Registry 集中管理、RPC channel_id 支持 |

**结论**：阶段三通过。Registry 正确抽取，循环依赖已消除，多频道 RPC 就绪，API 全兼容。可以进 M1。
