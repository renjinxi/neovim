# 风险问题修复方案

claude1 主导 + claude2 补充 | 2026-03-15

基于 claude2 风险分析报告 + 用户反馈，讨论优先级和实现方案。

---

## 1. 循环路由（低优先级，加轻量防护）

用户判断：当前任务模式（下任务→执行→汇报）不会出现循环。同意。

但仍建议加一个最小防护——**消息携带 depth 计数器**：

```lua
-- Bus:post 签名加 opts.depth
function Bus:post(from, content, opts)
    local depth = opts and opts.depth or 0
    ...
end

-- Bus:_route 传递 depth+1
function Bus:_route(content, from, depth)
    depth = depth or 0
    if depth >= 5 then
        log("WARN", "_route: depth limit  from=" .. from .. "  depth=" .. depth)
        return
    end
    ...
    self:_send_to(name, content, from, depth + 1)
end
```

改动量：3 行逻辑 + 参数透传。不影响正常流程，只在异常时生效。

---

## 2. Main 队列超时（P0，现在修）

### 问题

`_push_to_main` 的 `client:prompt()` 可能长时间不返回（大任务/网络卡），队列堆积，频道"死掉"。

### 方案

用 `vim.defer_fn` 做超时检测。不 kill prompt（main 可能还在正常工作），而是**允许队列继续处理**：

```lua
function Bus:_push_to_main(content, from)
    ...
    self._main_busy = true
    local timed_out = false

    -- 超时保护：120s 后释放队列锁
    local timeout_timer = vim.defer_fn(function()
        if self._main_busy then
            timed_out = true
            log("WARN", "_push_to_main: timeout 120s  releasing queue")
            self:post("系统", "⚠ main 响应超时(120s)，队列已释放", { no_route = true })
            self._main_busy = false
            main.status = "idle"
            self:_refresh_winbar()
            -- 处理队列
            if #self._main_queue > 0 then
                local next_item = table.remove(self._main_queue, 1)
                vim.schedule(function()
                    self:_push_to_main(next_item.content, next_item.from)
                end)
            end
        end
    end, 120000)

    main.client:prompt(payload, function(_)
        -- 如果已超时，不再处理队列（已被超时逻辑接管）
        if timed_out then
            -- 仍然收集回复 post 到频道
            if stream_buf ~= "" then
                vim.schedule(function()
                    self:post("main", "(延迟回复) " .. stream_buf)
                end)
            end
            return
        end
        -- 正常完成，取消超时
        pcall(vim.fn.timer_stop, timeout_timer)  -- 不确定 defer_fn 返回值，用 uv timer 更好
        ...原有逻辑...
    end)
end
```

**注意**：`vim.defer_fn` 返回的是 timer id，可以用 `vim.fn.timer_stop` 取消。验证一下 API。

更稳的写法用 `vim.uv.new_timer()`：

```lua
local timer = vim.uv.new_timer()
timer:start(120000, 0, vim.schedule_wrap(function()
    timer:close()
    if self._main_busy then
        ...超时处理...
    end
end))

-- prompt callback 里取消：
if not timer:is_closing() then timer:close() end
```

**超时时间**：120s。main 跑大任务（比如改代码+测试）可能需要几分钟，太短会误报。120s 是合理折中——如果 2 分钟还没反应，大概率卡住了。

---

## 3. 500ms defer 竞态（P1，现在修）

### 问题

`init.lua:open_bus` 里 `vim.defer_fn(fn, 500)` 等 main client 就绪。如果 handshake 超过 500ms，main 注册不上。

### 方案

**删掉 defer_fn**。`chat.on_ready` 回调（init.lua L213-221）已经是正确的事件驱动路径。defer_fn 是冗余的 fallback。

分析：
- 先开 chat 再开 bus → on_ready 已触发，defer_fn 负责注入 → 有用
- 先开 bus 再开 chat → defer_fn 时 client 未就绪，on_ready 后注入 → defer_fn 无效

第一种情况下，defer_fn 能 work 是因为 client 已经 ready。但这也意味着 on_ready 早就触发过了——只是当时 active_bus 不存在。

**修法**：在 `open_bus` 里同步检查已有 chat client，不需要 defer：

```lua
function M.open_bus(adapter_name, agent_name)
    if not active_bus then
        active_bus = require("acp.bus").new()
        active_bus:open()
        -- 同步注入已有的主 chat client
        for _, chat in pairs(active_chats) do
            if chat.client and chat.client.alive then
                active_bus.agents["main"].client = chat.client
                active_bus.agents["main"].status = "idle"
                active_bus.agents["main"].adapter_name = chat.adapter_name or "claude"
                active_bus:_refresh_winbar()
                active_bus:post("系统", "main 已上线")
                break
            end
        end
    end
    active_bus:add_agent(agent_name, adapter_name)
    return active_bus
end
```

如果 chat client 还没 ready（先 bus 后 chat），`chat.on_ready` 会在 client 就绪时注入。两条路径互补，无竞态。

---

## 4. Agent 崩溃后无重启（P1，现在修）

### 问题

agent 退出 → status="disconnected"，无法重启。用户只能 stop_all 重来。

### 方案

加 `:Acp restart <agent_name>` 子命令：

```lua
-- init.lua 的 Acp command handler 加分支
elseif sub == "restart" then
    M.restart_agent(args[2])

-- 实现
function M.restart_agent(agent_name)
    if not active_bus then
        vim.notify("[acp] 没有活跃频道", vim.log.levels.WARN)
        return
    end
    if not agent_name or agent_name == "" then
        vim.notify("[acp] 用法: :Acp restart <agent_name>", vim.log.levels.WARN)
        return
    end
    local agent = active_bus.agents[agent_name]
    if not agent then
        vim.notify("[acp] agent not found: " .. agent_name, vim.log.levels.WARN)
        return
    end
    if agent.kind == "local" then
        vim.notify("[acp] main agent 不能 restart，重新打开 chat", vim.log.levels.WARN)
        return
    end
    -- 清理旧进程
    if agent.chat then
        pcall(function() agent.chat:close() end)
    end
    -- 移除旧 agent，重新添加
    local adapter_name = agent.adapter_name
    active_bus.agents[agent_name] = nil
    active_bus:add_agent(agent_name, adapter_name)
end
```

注意 tab completion 里加 `restart`，以及 `parts[2] == "restart"` 时补全 agent 名。

**不做自动重启**——agent 退出可能是正常结束（任务做完），自动重启反而有害。手动 restart 更安全。

---

## 5. 同名 Agent 覆盖导致孤儿进程（P2，现在修）

### 问题

`add_agent` 覆盖 `self.agents[name]`，旧进程变孤儿。

### 方案

`add_agent` 入口检查：

```lua
function Bus:add_agent(name, adapter_name, opts)
    -- 同名检查：如果已存在且还活着，报错
    local existing = self.agents[name]
    if existing and existing.kind ~= "local" then
        if existing.client and existing.client.alive then
            self:post("系统", "⚠ " .. name .. " 已存在且在线，先 restart 再添加")
            return
        end
        -- 已断开的旧 agent，先清理
        if existing.chat then
            pcall(function() existing.chat:close() end)
        end
    end
    ...原有逻辑...
end
```

3 行检查 + 3 行清理，防止孤儿进程。

---

## 6. 修复汇总

| 问题 | 优先级 | 改动文件 | 改动量 |
|------|--------|----------|--------|
| 循环路由 depth 限制 | 低 | bus.lua | ~10 行 |
| Main 队列超时 | P0 | bus.lua | ~25 行 |
| 500ms defer 竞态 | P1 | init.lua | 删 defer_fn + 加同步检查，~10 行 |
| Agent restart 命令 | P1 | init.lua | ~25 行 |
| 同名 agent 覆盖检查 | P2 | bus.lua | ~10 行 |
| **共计** | | 2 文件 | ~80 行 |

建议实施顺序：P1 defer 竞态（最简单）→ P2 同名检查（简单）→ P0 超时（稍复杂）→ P1 restart → 循环 depth。

---

## claude2 补充区

（等 claude2 review 后补充意见）
