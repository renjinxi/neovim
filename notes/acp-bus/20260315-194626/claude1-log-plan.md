# P0 + P1 日志补充方案

## 日志基础设施

### chat.lua 加 log 函数

chat.lua 当前无日志。加一个和 bus.lua 风格一致的 log，写到同一个 LOG_DIR，文件名 `acp-chat.log`：

```lua
local LOG_DIR = vim.fn.stdpath("config") .. "/logs"
local LOG_FILE = LOG_DIR .. "/acp-chat.log"

local function log(level, msg)
    vim.fn.mkdir(LOG_DIR, "p")
    local f = io.open(LOG_FILE, "a")
    if not f then return end
    f:write(string.format("%s [%s] chat: %s\n", os.date("%H:%M:%S"), level, msg))
    f:close()
end
```

bus.lua 已有 log 函数，无需改动。

---

## P0：子 agent 启动路径 + agent 生命周期

### chat.lua

#### open_headless()（line 126）

在函数入口加：

```lua
log("INFO", "open_headless  adapter=" .. self.adapter_name
    .. "  bus_agent=" .. tostring(self.bus_agent_name))
```

#### _start_client()（line 184）

spawn 前加：

```lua
log("INFO", "_start_client  adapter=" .. self.adapter_name
    .. "  bus=" .. tostring(self.bus ~= nil)
    .. "  cwd=" .. (self.opts.cwd or vim.fn.getcwd()))
```

spawn 成功后（line 216 ok 分支）加：

```lua
log("INFO", "_start_client ok  adapter=" .. display_name)
```

spawn 失败（line 234 else 分支）加：

```lua
log("ERROR", "_start_client FAILED  adapter=" .. display_name
    .. "  err=" .. tostring(start_err))
```

#### on_ready 回调触发（line 230）

在 `if self.on_ready then` 前加：

```lua
log("INFO", "on_ready  adapter=" .. display_name
    .. "  session=" .. tostring(self.client and self.client.session_id))
```

#### on_exit（line 195）

已有 `_append_system` 调用。在它之前加：

```lua
log("INFO", "on_exit  adapter=" .. self.adapter_name
    .. "  code=" .. tostring(code)
    .. "  bus_agent=" .. tostring(self.bus_agent_name))
```

### bus.lua

#### add_agent()（line 273）

函数入口加：

```lua
log("INFO", "add_agent  name=" .. name .. "  adapter=" .. adapter_name)
```

on_ready 回调内（line 303-311）加：

```lua
log("INFO", "add_agent ready  name=" .. name
    .. "  session=" .. tostring(client.session_id))
```

#### agent 生命周期状态转换

在所有 `agent.status = "xxx"` 赋值处加日志。涉及：

1. **add_agent 注册时**（line 290-301，status="connecting"）：
   已有入口日志覆盖，不需要额外加。

2. **on_ready 里 status="idle"**（line 307）：
   已包含在 add_agent ready 日志里。

3. **send_to_agent 开始时 status="streaming"**（line 466）：
   ```lua
   log("INFO", "agent_status  name=" .. name .. "  connecting→streaming")
   ```
   见 P1 send_to_agent 日志，合并记录。

4. **send_to_agent callback status="idle"**（line 487）：
   同上，合并在 P1。

5. **on_exit status="disconnected"**（chat.lua on_exit 里设置 bus.agents[name].status）：
   chat.lua 的 on_exit 日志已覆盖。

---

## P1：消息路由 + on_update 转发

### bus.lua

#### _route()（line 337）

在路由循环内加：

```lua
-- 在 for name in pairs(mentioned) do 循环里，self:_send_to 前
log("DEBUG", "_route  from=" .. from .. "  → " .. name)
```

无 mention 命中时不需要日志（频繁且无信息量）。

#### _send_to()（line 349）

不加日志——_route 已记录了 `from → name`，_send_to 只是分发。避免重复。

#### send_to_agent()（line 453）

函数入口，替代之前缺失的日志：

```lua
log("INFO", "send_to_agent  name=" .. name
    .. "  sender=" .. tostring(sender)
    .. "  text_len=" .. #text
    .. "  first_prompt=" .. tostring(not agent.prompted))
```

prompt callback（line 484-518），完成时：

```lua
log("INFO", "send_to_agent done  name=" .. name
    .. "  stop=" .. tostring(stop_reason)
    .. "  reply_len=" .. #(agent.stream_buf or ""))
```

错误时（line 504 error 分支）：

```lua
log("ERROR", "send_to_agent error  name=" .. name
    .. "  " .. tostring(err and err.message or "unknown"))
```

agent 不在线时（line 455-458）：

```lua
log("WARN", "send_to_agent  name=" .. name .. "  not alive")
```

### chat.lua

#### _on_update bus 转发（line 320-323）

在转发前加：

```lua
log("DEBUG", "_on_update bus_forward  agent=" .. self.bus_agent_name
    .. "  kind=" .. tostring(kind))
```

注意用 DEBUG 级别——on_update 频繁调用（每个 chunk 都触发），INFO 会刷爆日志。

#### _submit_input bus 路由（line 258-264）

bus 模式分支里加：

```lua
log("INFO", "_submit_input  bus_route  agent=" .. self.bus_agent_name
    .. "  text_len=" .. #text)
```

---

## 日志级别规范

| 级别 | 用途 | 频率 |
|------|------|------|
| ERROR | spawn 失败、send 错误 | 罕见 |
| WARN | agent 不在线、main 未连接 | 偶尔 |
| INFO | 生命周期事件（启动/就绪/退出/发送/完成） | 每次操作 |
| DEBUG | 路由决策、on_update 转发 | 高频 |

## 文件汇总

| 文件 | 新增日志数 | 优先级 |
|------|-----------|--------|
| chat.lua | 7 条（含 log 函数） | P0+P1 |
| bus.lua | 6 条 | P0+P1 |
| 共计 | 13 条 | |
