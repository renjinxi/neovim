# 子 agent 统一走 ACP Chat 启动 — 方案

## 核心思路

bus:add_agent 不再直接 client.create()，而是创建 Chat 实例。Chat 实例既是独立对话 UI，又是 bus 的 agent 载体。

## 现有问题

bus.lua add_agent 做了三件事：
1. 创建 client（spawn 进程 + 握手）
2. 创建 chat_buf（只读，无输入框）
3. 注册到 agents 表 + 接管 on_update

chat.lua 已经做了 1 和 2（还带输入框），但没有和 bus 关联的机制。两套并行是浪费。

## 方案

### Chat 改动：支持 bus 模式

Chat.new 加 `bus` 参数：

```lua
function Chat.new(adapter_name, opts)
  opts = opts or {}
  return setmetatable({
    adapter_name = adapter_name,
    opts = opts,
    client = nil,
    buf = nil,
    win = nil,
    input_buf = nil,
    input_win = nil,
    streaming = false,
    stream_started = false,
    on_ready = nil,
    bus = nil,           -- 关联的 Bus 实例
    bus_agent_name = nil, -- 在 bus 中的名字
  }, Chat)
end
```

新增 `open_headless()` 方法——只创建 buffer + client，不创建窗口：

```lua
function Chat:open_headless()
  -- 创建 buffer（和 open 一样），但不创建 window
  self.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[self.buf].buftype = "nofile"
  vim.bo[self.buf].bufhidden = "hide"
  vim.bo[self.buf].swapfile = false
  vim.bo[self.buf].filetype = "markdown"
  pcall(vim.api.nvim_buf_set_name, self.buf, "acp://agent/" .. (self.bus_agent_name or self.adapter_name) .. "/" .. os.time())

  -- 创建 input_buf（用户打开窗口时需要）
  self.input_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[self.input_buf].buftype = "nofile"
  vim.bo[self.input_buf].bufhidden = "hide"
  vim.bo[self.input_buf].swapfile = false

  -- 欢迎
  vim.bo[self.buf].modifiable = true
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, {
    "# Agent: " .. (self.bus_agent_name or self.adapter_name),
    "",
    "连接中...",
  })
  vim.bo[self.buf].modifiable = false

  -- cleanup autocmds（和 open 一样）
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = self.buf, once = true,
    callback = function()
      if self.client then pcall(function() self.client:stop() end) end
    end,
  })

  -- 启动 client
  vim.schedule(function() self:_start_client() end)
end
```

### Chat on_update 转发给 bus

Chat._on_update 现在只更新自己的 buffer。加一段：如果关联了 bus，同时转发 update 给 bus：

```lua
function Chat:_on_update(params)
  -- 现有逻辑：更新自己的 buf
  -- ...（不变）

  -- bus 模式：转发给 bus
  if self.bus and self.bus_agent_name then
    self.bus:_on_agent_update(self.bus_agent_name, params)
  end
end
```

同理，on_exit 也转发：

```lua
-- 在 _start_client 里
on_exit = function(code, _)
  vim.schedule(function()
    self:_append_system("进程退出 (code=" .. tostring(code) .. ")")
    self:_refresh_winbar()
    -- bus 模式：通知 bus
    if self.bus and self.bus_agent_name then
      if self.bus.agents[self.bus_agent_name] then
        self.bus.agents[self.bus_agent_name].status = "disconnected"
      end
      self.bus:post("系统", self.bus_agent_name .. " 退出 (code=" .. tostring(code) .. ")")
      self.bus:_refresh_winbar()
    end
  end)
end,
```

### Chat.send 增加 bus 回发

prompt 完成后，如果关联了 bus，把 agent 的完整回复 post 到频道：

```lua
-- 在 send() 的 prompt callback 里
-- 现有逻辑：self.streaming = false, _refresh_winbar
-- 新增：
if self.bus and self.bus_agent_name then
  -- stream_buf 需要 Chat 也维护（现在只有 bus 的 agent 结构维护）
  -- 或者从 bus.agents 里拿
end
```

**这里有个决策点**：stream_buf 谁维护？

方案A：Chat 自己维护 stream_buf，bus 通过 chat 读取。
方案B：bus 的 _on_agent_update 自己累积（现有逻辑不变）。

**建议方案B**，原因：bus 的 _on_agent_update 已经有完整的累积 + 日志逻辑，Chat 只负责 buffer 渲染。职责清晰。

### bus:add_agent 改造

```lua
function Bus:add_agent(name, adapter_name, opts)
  opts = opts or {}
  local chat_mod = require("acp.chat")

  -- 创建 Chat 实例，关联 bus
  local chat = chat_mod.new(adapter_name, vim.tbl_extend("force", opts, {
    bus_mode = true,
    agent_name = name,
    channel_id = self.channel_id,
  }))
  chat.bus = self
  chat.bus_agent_name = name

  -- 注入 system_prompt（频道模式）
  local adapter_config = adapter_mod.get(adapter_name, {
    bus_mode = true,
    agent_name = name,
    channel_id = self.channel_id,
  })

  -- headless 启动（不创建窗口）
  chat:open_headless()

  -- on_ready 回调：注册到 agents 表
  chat.on_ready = function(client)
    self.agents[name] = {
      kind = "spawned",
      client = client,
      chat = chat,        -- 新增：持有 Chat 引用
      status = "idle",
      adapter_name = adapter_name,
      streaming = false,
      stream_buf = "",
      stream_started = false,
      system_prompt = adapter_config.system_prompt,
      prompted = false,
      chat_buf = chat.buf,  -- 直接用 Chat 的 buf
    }
    self:post("系统", name .. " (" .. adapter_name .. ") 已上线")
    self:_refresh_winbar()
  end
end
```

### bus:send_to_agent 适配

现有 send_to_agent 直接操作 agent.client:prompt()。改为通过 Chat.send()？

**不建议**。原因：
1. Chat.send() 会渲染 user 消息到 chat buffer（好的，我们需要这个）
2. 但 Chat.send() 的 prompt callback 只处理 stop_reason，不处理 bus 频道的逻辑（错误通知发送者、日志写入等）

**建议保持现有 send_to_agent 逻辑不变**，它直接操作 agent.client:prompt()。Chat 通过 on_update 转发已经能同步 buffer 渲染。唯一改动：send_to_agent 写 user 消息到 chat buffer 的逻辑，改为调 chat:_append_role()：

```lua
-- 现有
self:_append_agent_role(agent, "You", text)
-- 改为
if agent.chat then
  agent.chat:_append_role("You", text)
end
```

类似地，_append_agent_chunk / _append_agent_system 改为调 chat 方法。

但这引入了 bus 对 Chat 内部方法的依赖。

**更好的方案**：让 Chat 的 on_update 转发机制处理所有 buffer 更新，bus 不再直接操作 chat_buf。

流程变为：
1. bus:send_to_agent → agent.client:prompt()（不变）
2. client 产生 on_update → Chat._on_update → 更新 Chat buffer + 转发给 bus
3. bus._on_agent_update → 只处理 bus 侧逻辑（winbar、activity、stream_buf、日志）

这样 bus 里的 _append_agent_role / _append_agent_chunk / _append_agent_system 可以全部删掉。

### bus:open_agent_buf 适配

现有逻辑直接 vsplit 打开 agent.chat_buf。改为调 chat:show()，这样用户能得到完整的 Chat UI（含输入框），可以直接和子 agent 对话。

```lua
function Bus:open_agent_buf(name)
  local agent = self.agents[name]
  if not agent or not agent.chat then
    vim.notify("[acp] agent not found: " .. name, vim.log.levels.WARN)
    return
  end
  agent.chat:show()
end
```

**关键变化**：用户打开子 agent 的 Chat 后，可以通过输入框直接和它对话，不经过 bus。这是功能增强，但需要注意：
- 直接对话的消息不会出现在 bus 频道里
- 这可能是想要的行为（私聊 vs 频道），也可能让用户困惑

**建议**：bus 模式下，Chat 输入框的提交走 bus 路由而非直接 send：

```lua
function Chat:_submit_input()
  -- ...
  if self.bus and self.bus_agent_name then
    -- 通过 bus 路由（消息会显示在频道里）
    local text_with_mention = "@" .. self.bus_agent_name .. " " .. text
    self.bus:post("你", text_with_mention)
  else
    self:send(text)
  end
end
```

### 删除 bus 里的冗余代码

统一后可删除：
- `_append_agent_role()`
- `_append_agent_chunk()`
- `_append_agent_system()`

_on_agent_update 精简为只处理 bus 侧逻辑（不操作 buffer）。

### store 兼容

agents 表新增 `chat` 字段是 Chat 实例，序列化时忽略它（store.lua 已经只取 name/kind/adapter/session_id）。无影响。

## 改动清单

| 文件 | 改动 |
|------|------|
| chat.lua | 加 bus/bus_agent_name 字段，open_headless()，on_update 转发，on_exit 转发，_submit_input bus 路由 |
| bus.lua | add_agent 改用 Chat，agents 表加 chat 字段，删 _append_agent_* 3 个函数，open_agent_buf 改用 chat:show() |
| init.lua | 无改动（open_chat 已经创建 Chat 实例） |
| adapter.lua | 无改动 |
| store.lua | 无改动 |
| rpc.lua | 无改动 |

## 风险点

1. **on_update 双重处理**：Chat._on_update 更新 buffer，bus._on_agent_update 更新状态。需确保不冲突。关键：bus 不再操作 buffer，只管状态和日志。
2. **send_to_agent 的 system_prompt 前置**：现在在 bus 里做。Chat 不知道 system_prompt。保持在 bus 里做就行，因为是直接调 client:prompt()。
3. **Chat 的 prompt callback vs bus 的 prompt callback**：bus send_to_agent 直接调 client:prompt()，Chat 不知道这次 prompt。Chat 的 on_update 转发能保证 buffer 同步，但 Chat.streaming 状态不会更新。需要 bus 同步设置 chat.streaming。

## 执行顺序建议

1. Chat 加 open_headless() + bus 字段
2. Chat._on_update 加转发
3. bus:add_agent 改用 Chat
4. 验证 on_update 双通道正常
5. 删 bus 里的 _append_agent_* 函数
6. open_agent_buf 改用 chat:show()
7. Chat._submit_input 加 bus 路由
