# claude2 补充意见：修复方案

## 1. 循环路由 — 轻量检测

同意用户判断，当前任务模式下概率低。最轻量的方案：

```lua
-- Bus:post 加 opts.depth 参数
function Bus:post(from, content, opts)
    local depth = opts and opts.depth or 0
    if depth > 3 then
        log("WARN", "route depth exceeded: " .. from .. " → " .. content:sub(1,40))
        return  -- 静默丢弃，不 post
    end
    -- ... 原逻辑
    -- _route 时传递 depth+1
end
```

改动点：post() 加 depth 字段，_route → _send_to 透传，超过阈值丢弃 + 日志。3 行核心逻辑，不影响正常流程。

**不建议现在修**，但可以先加日志监控（在 _route 里 log depth），观察实际调用深度。

## 2. main 队列超时 — 建议现在修

这是最容易命中的问题。方案：

```lua
-- _push_to_main 里，发 prompt 前启动超时定时器
local timer = vim.defer_fn(function()
    if self._main_busy then
        self._main_busy = false
        main.status = "idle"
        self:post("系统", "⚠ main 响应超时，跳过当前消息", { no_route = true })
        -- 继续处理队列
        if #self._main_queue > 0 then
            local next_item = table.remove(self._main_queue, 1)
            vim.schedule(function()
                self:_push_to_main(next_item.content, next_item.from)
            end)
        end
    end
end, 120000)  -- 120s，main 可能在跑复杂任务
```

**注意**：prompt 正常完成时要 cancel timer，否则误触。需要存 timer handle。

超时时间建议 120s 而非 60s — main 经常在做代码修改，60s 太短会误杀。

## 3. 500ms defer 竞态 — 建议现在修

init.lua:231 的 defer_fn(500) 是历史遗留。现在 open_chat 已经有 on_ready 回调（init.lua:213），**两条路径重复了**：

- 路径 A：open_chat.on_ready → 直接注册 main client（事件驱动，可靠）
- 路径 B：open_bus 里 defer_fn(500) → 尝试注册（定时器，不可靠）

**修法**：删掉 open_bus 里的 defer_fn 块（init.lua:231-244），只靠路径 A。

但有个前提：必须保证 open_bus 在 open_chat 之后调用时，on_ready 已经设置好。看代码流程：
- 用户先 `:Acp chat claude` → active_chats 有 chat，但 on_ready 已经触发过了
- 再 `:Acp bus claude agent1` → open_bus → defer_fn 是唯一注册路径

所以 **defer_fn 不能直接删**，要改成：open_bus 检测到已有 chat.client 时立即注册，不走 defer。

```lua
-- open_bus 里替换 defer_fn 块
if active_bus and active_bus.agents["main"] and not active_bus.agents["main"].client then
    for _, chat in pairs(active_chats) do
        if chat.client then
            active_bus.agents["main"].client = chat.client
            active_bus.agents["main"].status = "idle"
            active_bus.agents["main"].adapter_name = chat.adapter_name or "claude"
            active_bus:_refresh_winbar()
            active_bus:post("系统", "main 已上线")
            break
        end
    end
end
```

同步检测，无竞态。如果 chat 还在握手中，on_ready 回调会兜底。

## 4. agent 重启 — 建议 P2，但方案先定

```lua
-- init.lua 加子命令
elseif sub == "restart" then
    local name = args[2]
    if not name or not active_bus then return end
    local agent = active_bus.agents[name]
    if not agent or agent.kind == "local" then return end
    -- 关旧的
    if agent.chat then pcall(function() agent.chat:close() end) end
    active_bus.agents[name] = nil
    -- 重开
    active_bus:add_agent(name, agent.adapter_name)
```

简单粗暴但够用。

## 5. 同名 agent 覆盖 — 一行防御

```lua
-- bus.lua add_agent 开头加
if self.agents[name] and self.agents[name].kind ~= "local" then
    self:post("系统", name .. " 已存在，先 stop 再重新添加")
    return
end
```

## 修复优先级建议

| 顺序 | 问题 | 理由 |
|------|------|------|
| 1 | 500ms defer 竞态 | 最小改动，删 defer + 同步检测 |
| 2 | main 队列超时 | 最容易命中，改动集中在 _push_to_main |
| 3 | 同名 agent 防御 | 一行代码 |
| 4 | agent restart | 新功能，不急 |
| 5 | 循环路由 | 先加监控日志观察 |
