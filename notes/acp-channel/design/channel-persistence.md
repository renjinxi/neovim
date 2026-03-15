# 频道持久化设计

## 需求
频道关闭/nvim退出时自动保存快照，`:AcpBusSelect` 命令恢复历史频道。

## 存储位置
```
~/.local/state/nvim/acp-channels/{cwd编码}/{channel_id}.json
```

cwd编码规则：去掉开头 `/`，所有 `/` 替换为 `-`
例：`/Users/renjinxi/.config/nvim` → `Users-renjinxi-.config-nvim`

## 快照数据结构
```json
{
  "version": 1,
  "channel_id": "20260315-143000",
  "saved_at": "2026-03-15T14:30:00",
  "cwd": "/Users/renjinxi/.config/nvim",
  "agents": [
    {"name": "codex", "adapter": "codex", "session_id": "xxx"}
  ],
  "history": [
    {"from": "main", "content": "...", "timestamp": 1773559873}
  ]
}
```

## 实现计划

### 1. 新建 `lua/acp/store.lua`（~80行）

```lua
local M = {}
local json_encode = vim.fn.json_encode
local json_decode = vim.fn.json_decode

--- cwd 编码
local function encode_cwd(cwd)
  return cwd:gsub("^/", ""):gsub("/", "-")
end

--- 存储目录
local function storage_dir(cwd)
  return vim.fn.stdpath("state") .. "/acp-channels/" .. encode_cwd(cwd)
end

--- 保存频道快照
function M.save(bus, cwd)
  if not bus.messages or #bus.messages == 0 then return end
  local agents = {}
  for name, agent in pairs(bus.agents) do
    agents[#agents + 1] = {
      name = name,
      adapter = agent.adapter_name or (agent.client and agent.client.adapter and agent.client.adapter.name) or "unknown",
      session_id = agent.client and agent.client.session_id or vim.NIL,
    }
  end
  local snapshot = {
    version = 1,
    channel_id = bus.channel_id,
    saved_at = os.date("%Y-%m-%dT%H:%M:%S"),
    cwd = cwd,
    agents = agents,
    history = bus.messages,
  }
  local dir = storage_dir(cwd)
  vim.fn.mkdir(dir, "p")
  local filepath = dir .. "/" .. bus.channel_id .. ".json"
  local f = io.open(filepath, "w")
  if not f then return end
  f:write(json_encode(snapshot))
  f:close()
end

--- 列出已保存的频道（按时间倒序）
function M.list(cwd)
  local dir = storage_dir(cwd)
  local files = vim.fn.glob(dir .. "/*.json", false, true)
  local result = {}
  for _, filepath in ipairs(files) do
    local f = io.open(filepath, "r")
    if f then
      local ok, snapshot = pcall(json_decode, f:read("*a"))
      f:close()
      if ok and snapshot then
        local agent_names = {}
        for _, a in ipairs(snapshot.agents or {}) do
          agent_names[#agent_names + 1] = a.name .. "(" .. a.adapter .. ")"
        end
        result[#result + 1] = {
          channel_id = snapshot.channel_id,
          saved_at = snapshot.saved_at,
          agents = table.concat(agent_names, ", "),
          msg_count = snapshot.history and #snapshot.history or 0,
          filepath = filepath,
        }
      end
    end
  end
  table.sort(result, function(a, b) return a.channel_id > b.channel_id end)
  return result
end

--- 加载频道快照
function M.load(filepath)
  local f = io.open(filepath, "r")
  if not f then return nil end
  local ok, snapshot = pcall(json_decode, f:read("*a"))
  f:close()
  if ok then return snapshot end
  return nil
end

--- 删除快照
function M.delete(filepath)
  os.remove(filepath)
end

return M
```

### 2. 修改 `lua/acp/bus.lua`

#### 2a. `Bus.new()` 加字段
```lua
function Bus.new()
  local channel_id = os.date("%Y%m%d-%H%M%S")
  return setmetatable({
    channel_id = channel_id,
    cwd = vim.fn.getcwd(),
    -- ... 其余不变 ...
    _saved = false,
  }, Bus)
end
```

#### 2b. `open()` 里 session_dir 用 self.channel_id
把：
```lua
local session_id = os.date("%Y%m%d-%H%M%S")
self.session_dir = LOG_DIR .. "/bus-" .. session_id
```
改为：
```lua
self.session_dir = LOG_DIR .. "/bus-" .. self.channel_id
```

#### 2c. `add_agent()` 里加 adapter_name
在 `self.agents[name] = {` 里加一行：
```lua
adapter_name = adapter_name,
```

#### 2d. VimLeavePre autocmd 里加保存
```lua
callback = function()
  self:save_snapshot()  -- 加这行
  self:_cleanup_agents()
end,
```

#### 2e. 新增方法（加在 close() 前面）
```lua
--- 保存频道快照
function Bus:save_snapshot()
  if self._saved then return end
  self._saved = true
  local store = require("acp.store")
  store.save(self, self.cwd)
end

--- 从快照恢复：回填历史 + 重新启动 agent
function Bus:restore_from_snapshot(snapshot)
  self.channel_id = snapshot.channel_id
  self.cwd = snapshot.cwd or vim.fn.getcwd()
  -- 回填历史
  if snapshot.history then
    for _, msg in ipairs(snapshot.history) do
      self.messages[#self.messages + 1] = msg
      self:_render_message(msg)
    end
  end
  -- 重启 agent（新 session）
  if snapshot.agents then
    for _, agent_info in ipairs(snapshot.agents) do
      local ok, err = pcall(function()
        self:add_agent(agent_info.name, agent_info.adapter)
      end)
      if not ok then
        self:post("系统", agent_info.name .. " 恢复失败: " .. tostring(err))
      end
    end
  end
end
```

#### 2f. `close()` 开头加保存
```lua
function Bus:close()
  self:save_snapshot()  -- 加这行
  self:_cleanup_agents()
  -- ... 其余不变
end
```

### 3. 修改 `lua/acp/init.lua`

#### 3a. setup() 里加命令（放在 AcpToggle 前面）
```lua
vim.api.nvim_create_user_command("AcpBusSelect", function()
  M.select_bus()
end, { desc = "ACP: 恢复已保存的频道" })
```

#### 3b. 新增函数（放在 bus_post 前面）
```lua
--- 选择并恢复已保存的频道
function M.select_bus()
  local store = require("acp.store")
  local cwd = vim.fn.getcwd()
  local channels = store.list(cwd)
  if #channels == 0 then
    vim.notify("[acp] 当前目录没有已保存的频道", vim.log.levels.INFO)
    return
  end
  local items = {}
  for _, ch in ipairs(channels) do
    items[#items + 1] = string.format("%s  [%s]  %d条消息", ch.channel_id, ch.agents, ch.msg_count)
  end
  vim.ui.select(items, { prompt = "恢复频道" }, function(_, idx)
    if not idx then return end
    local selected = channels[idx]
    local snapshot = store.load(selected.filepath)
    if not snapshot then
      vim.notify("[acp] 快照加载失败", vim.log.levels.ERROR)
      return
    end
    if active_bus then
      pcall(function() active_bus:close() end)
      active_bus = nil
    end
    active_bus = require("acp.bus").new()
    active_bus:open()
    active_bus:restore_from_snapshot(snapshot)
  end)
end
```

## 注意事项
- 中文注释
- `:AcpBus` 不变，始终新建
- 不做 session/load，恢复时 agent 走新 session
- 空频道不保存
