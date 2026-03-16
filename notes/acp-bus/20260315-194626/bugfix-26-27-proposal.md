# Bug #26 + #27 修复方案

claude1 | 2026-03-16

---

## Bug #26: 多 Chat 实例导致 main 身份冲突

### 根因

`init.lua:open_chat()` L213 的 `on_ready` 回调**无条件**覆写 `active_bus.agents["main"].client`：

```lua
chat.on_ready = function(client)
    if active_bus and active_bus.agents["main"] then
        active_bus.agents["main"].client = client  -- 无条件覆写！
```

场景：
1. `:Acp chat claude` → chat1 创建，on_ready 注册 main = chat1.client
2. `:Acp bus claude agent1` → bus 创建，从 active_chats 找到 chat1 注入 main
3. `:Acp chat c1` → chat2 创建（adapter 不同，不走 toggle），on_ready 再次触发 → **main.client 被替换为 chat2.client**

chat1 仍在 active_chats 里但与 bus 断开。bus 里的 main 指向 c1 而非预期的 claude。

### 修复

on_ready 加守卫：只有 main 没有活跃 client 时才注册。

```lua
-- init.lua open_chat() L213
chat.on_ready = function(client)
    if active_bus and active_bus.agents["main"] then
        local main = active_bus.agents["main"]
        -- 只在 main 无活跃 client 时注册
        if not main.client or not main.client.alive then
            main.client = client
            main.status = "idle"
            main.adapter_name = adapter_name
            active_bus:_refresh_winbar()
            active_bus:post("系统", "main (" .. adapter_name .. ") 已上线")
        end
    end
end
```

如果用户想主动切换 main 的 client，后续可加 `:Acp set-main <chat_name>` 命令。

**改动量**：2 行（加 if 守卫）

---

## Bug #27: Main 输出意外打到频道

### 根因

`_push_to_main()` L426-436 用 **monkey-patch** 替换 `main.client.on_update` 来截获流式输出：

```lua
local orig_on_update = main.client.on_update
main.client.on_update = function(params)
    if orig_on_update then orig_on_update(params) end  -- 原有处理
    -- 截获 text 到 stream_buf
end
main.client:prompt(content, function(_)
    main.client.on_update = orig_on_update  -- 恢复
    self:post("main", stream_buf)  -- 发到频道
end)
```

**问题**：monkey-patch 是 client 级别的，截获的是 ALL updates，不只是 bus prompt 的。

竞态场景：
1. 用户在 main Chat 输入框直接发消息 → `Chat.send()` → `client:prompt(A)` → `Chat.streaming = true`
2. Bus 路由 @main 消息 → `_push_to_main()` → monkey-patch on_update → `client:prompt(B)`
3. 现在两个 prompt 同时 in-flight，monkey-patch 截获 **A+B 的所有输出** 到 stream_buf
4. B 完成时，A 的输出也被 post 到频道 → **泄漏**

更常见的场景：即使没有并发，monkey-patch 期间 main 的**任何** session/update（包括 tool_call_update 等非 message chunk）都经过 monkey-patch → `orig_on_update` 触发 `Chat._on_update` 正常渲染 → 没问题。但如果 `_on_update` 里未来加了 bus forward 逻辑（比如 main Chat 也设了 `self.bus`），就会双重 forward。

### 修复（两步）

#### Step 1: 防止并发 prompt

在 `_push_to_main` 入口加 `main_chat.streaming` 检查。如果 main Chat 正在直接对话，入队等待：

```lua
function Bus:_push_to_main(content, from)
    local main = self.agents["main"]
    -- ...existing nil/alive checks...

    -- 如果 main Chat 正在直接对话，也入队
    local main_chat = self:_find_main_chat()
    if main_chat and main_chat.streaming then
        log("INFO", "_push_to_main: main chat busy, queueing")
        self._main_queue[#self._main_queue + 1] = { content = content, from = from }
        self:_refresh_winbar()
        self:_schedule_main_queue_drain()
        return
    end

    if self._main_busy then
        -- ...existing queue logic...
    end
    -- ...rest of function...
end
```

```lua
--- 延迟检查队列（等 main chat 空闲后排水）
function Bus:_schedule_main_queue_drain()
    if self._drain_pending then return end
    self._drain_pending = true
    vim.defer_fn(function()
        self._drain_pending = nil
        if self._main_busy or #self._main_queue == 0 then return end
        local main_chat = self:_find_main_chat()
        if main_chat and main_chat.streaming then
            self:_schedule_main_queue_drain()  -- 还在忙，继续等
            return
        end
        local next_item = table.remove(self._main_queue, 1)
        self:_push_to_main(next_item.content, next_item.from)
    end, 500)
end
```

#### Step 2: 用 on_chunk 替代 monkey-patch

client.lua 已经支持 `on_chunk` 参数（L172），独立于 `on_update`。用它来收集 bus prompt 的输出，不再碰全局 on_update：

```lua
-- 替换 _push_to_main 里的 monkey-patch 段（L425-462）
local stream_buf = ""

-- 不再 monkey-patch on_update
main.client:prompt(content, function(_)
    -- on_done
    local elapsed = math.floor((os.clock() - t0) * 1000)
    log("INFO", "_push_to_main: done  elapsed=" .. elapsed .. "ms  reply_len=" .. #stream_buf)
    if stream_buf ~= "" then
        vim.schedule(function()
            self:post("main", stream_buf)
        end)
    end
    self._main_busy = false
    main.status = "idle"
    if main_chat then
        main_chat.streaming = false
        main_chat:_refresh_winbar()
    end
    self:_refresh_winbar()
    if #self._main_queue > 0 then
        local next_item = table.remove(self._main_queue, 1)
        vim.schedule(function()
            self:_push_to_main(next_item.content, next_item.from)
        end)
    end
end, function(params)
    -- on_chunk：只收集 text，不影响全局 on_update
    if not params or not params.update then return end
    local kind = params.update.sessionUpdate
    if kind == "agent_message_chunk" then
        local text = self:_extract_text(params.update.content)
        if text ~= "" then stream_buf = stream_buf .. text end
    end
end)
```

**注意**：`on_chunk` 是 client 级别的字段（`self._on_chunk`），并发时会互相覆盖。但 Step 1 已经防止了并发 prompt，所以这里安全。

### 改动量

| 文件 | 改动 |
|------|------|
| bus.lua `_push_to_main` | ~15 行（加 streaming 检查 + on_chunk 替代 monkey-patch）|
| bus.lua 新增 `_schedule_main_queue_drain` | ~15 行 |
| bus.lua `Bus.new` | 加 `_drain_pending = false` 字段 |
| init.lua `open_chat` on_ready | 2 行（加守卫）|
| **共计** | ~35 行 |

---

## 实施顺序

1. **#26 先修**（2 行，无风险）
2. **#27 Step 1**（streaming 检查 + drain timer）
3. **#27 Step 2**（on_chunk 替代 monkey-patch）

Step 1 和 Step 2 可以合并一次改。
