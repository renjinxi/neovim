# 议题1：命令精简 + 快捷键 v2

## 分析：6 个命令的使用频率

| 命令 | 频率 | 场景 |
|------|------|------|
| AcpToggle | 极高 | 编码中随时切换 ACP 窗口 |
| AcpAgents | 高 | 选择/切换具体 session |
| AcpChat | 中 | 首次开私聊 |
| AcpBus | 中 | 首次开频道 |
| AcpBusSelect | 低 | 恢复旧频道 |
| AcpStop | 低 | 关闭所有 |

## 合并方案：6 → 3

### 合并1：AcpChat + AcpBus + AcpBusSelect → Acp

一个命令根据参数决定行为：

```
:Acp           → 无参数：如果有活跃会话就 toggle，没有就开 claude chat
:Acp chat      → 开私聊（默认 claude）
:Acp chat c1   → 开 c1 私聊
:Acp bus       → 开/toggle 频道
:Acp bus c1 w1 → 频道加 agent
:Acp restore   → 恢复已保存频道
:Acp stop      → 关闭所有
:Acp list      → picker（= AcpAgents）
```

这样命令从 6 个变 1 个。子命令用 complete 补全。

### 合并2：AcpAgents 升级为 Acp 的默认行为

`Acp` 无参数时的逻辑：
1. 有活跃会话 → AcpToggle 行为（toggle 最近活跃的）
2. 没有活跃会话 → 直接打开 claude chat（零配置启动）

这让 `Acp` 成为唯一需要记的命令。

### 快捷键：只绑 2 个

| 快捷键 | 效果 | 按键数 |
|--------|------|--------|
| `<A-u>` | `:Acp`（toggle / 首次启动） | 1 |
| `<A-i>` | `:Acp list`（picker） | 1 |

**只需要 2 个 Alt 键**，覆盖 99% 场景：
- `<A-u>` 盲按 toggle，最常用
- `<A-i>` 需要选择时，调 picker

`<A-u>` 和 `<A-i>` 相邻，形成操作对。`<A-i>` 当前未使用。

其余操作（bus、restore、stop）用命令 `:Acp xxx`，不绑键——低频操作不值得占快捷键。

### 代码改动

init.lua 里只注册一个命令：

```lua
vim.api.nvim_create_user_command("Acp", function(opts)
    local args = vim.split(opts.args, "%s+")
    local sub = args[1] or ""
    if sub == "" then
        -- toggle / 首次启动
        M.toggle_or_start()
    elseif sub == "chat" then
        M.open_chat(args[2] or "claude", { api_num = args[3] and tonumber(args[3]) })
    elseif sub == "bus" then
        M.open_bus(args[2] or "claude", args[3])
    elseif sub == "list" then
        M.show_picker()
    elseif sub == "restore" then
        M.select_bus()
    elseif sub == "stop" then
        M.stop_all()
    else
        vim.notify("[acp] 未知子命令: " .. sub, vim.log.levels.ERROR)
    end
end, {
    nargs = "*",
    desc = "ACP 统一入口",
    complete = function(arg_lead, line)
        local parts = vim.split(line, "%s+")
        if #parts <= 2 then
            return vim.tbl_filter(function(s)
                return s:find(arg_lead, 1, true) == 1
            end, { "chat", "bus", "list", "restore", "stop" })
        elseif parts[2] == "chat" or parts[2] == "bus" then
            return require("acp.adapter").list()
        end
        return {}
    end,
})
```

旧命令可以保留为别名（兼容期），也可以直接删。

all.lua：

```lua
-- alt_mappings
{ "<A-u>", "<cmd>Acp<cr>", desc = "ACP Toggle", mode = { "n", "i", "v", "t" } },
{ "<A-i>", "<cmd>Acp list<cr>", desc = "ACP Picker", mode = { "n", "i", "v", "t" } },

-- 删除所有 <leader>ai* 和 <leader>u* 绑定
```

---

# 议题2：调起原生 CLI

## session_id 追踪

当前保存链路：
1. `client.lua:162` — `self.session_id = session_result.sessionId`
2. `store.lua:29` — 快照里 `session_id = agent.client.session_id`
3. 运行时：`bus.agents[name].client.session_id` 随时可读

session_id 在 client 存活期间始终可用。快照里也持久化了。

## 原生 CLI 恢复命令

Claude Code: `claude --resume SESSION_ID`
Gemini: 未知是否支持 resume（待确认）
Codex: 未知

## 方案：AcpAgents picker 加 "原生 CLI" 选项

在 picker 里，每个 agent 旁边加一个 `[CLI]` 操作。或者更简单：选中 agent 后弹二级菜单。

**建议最简方案**：在 picker 的 action 里加长按/二次确认，或直接加一个命令：

```
:Acp cli <agent_name>
```

实现：

```lua
elseif sub == "cli" then
    local agent_name = args[2]
    M.open_native_cli(agent_name)
```

```lua
function M.open_native_cli(agent_name)
    if not active_bus then
        vim.notify("[acp] 没有活跃频道", vim.log.levels.WARN)
        return
    end
    local agent = active_bus.agents[agent_name]
    if not agent then
        vim.notify("[acp] agent not found: " .. tostring(agent_name), vim.log.levels.WARN)
        return
    end
    local session_id = agent.client and agent.client.session_id
    if not session_id then
        vim.notify("[acp] agent 没有 session_id", vim.log.levels.WARN)
        return
    end
    local adapter_name = agent.adapter_name or "claude"
    local cmd
    if adapter_name == "claude" or adapter_name == "c1" or adapter_name == "c2" then
        cmd = "claude --resume " .. session_id
    else
        vim.notify("[acp] " .. adapter_name .. " 不支持原生 CLI resume", vim.log.levels.WARN)
        return
    end
    -- 在新 tab 里开终端
    vim.cmd("tabnew | terminal " .. cmd)
end
```

### picker 集成

在 AcpAgents picker（即 `Acp list`）里，每个 agent 加一个 `→ CLI` 选项：

```
[bus]  频道
[agent:claude-1]  idle  ✓
[agent:claude-1]  → 原生 CLI    ← 新增
```

或者更优雅：选中 agent 后弹二级菜单 `{ "Toggle 窗口", "原生 CLI", "取消" }`。

**建议先用命令 `:Acp cli agent_name`**，picker 集成以后再做。原因：
1. 命令方式立刻可用
2. picker 二级菜单需要更多 UI 工作
3. 用户说是"保底方案"，低频使用

### 从快照恢复原生 CLI

快照里有 session_id，可以从历史频道恢复：

```
:Acp restore   → 选择频道 → 恢复后 :Acp cli agent_name
```

也可以做一个 `:Acp cli-restore` 直接从快照里选 agent 并打开原生 CLI，但暂时不需要。

## 风险

1. `claude --resume` 会接管 session，和 ACP client 争抢。**建议**：打开原生 CLI 前先把 ACP client 停掉（`agent.client:stop()`），避免冲突
2. c1/c2 用的是 `claude-agent-acp`，不是 `claude`。原生 CLI 用 `claude` 命令，但 base_url/token 不同。需要构建正确的 env：

```lua
local env_str = ""
if adapter_name == "c1" then
    -- 从 adapter 配置拿 env
    local adapter_config = require("acp.adapter").get("c1", {})
    for k, v in pairs(adapter_config.env) do
        env_str = env_str .. k .. "=" .. v .. " "
    end
end
cmd = env_str .. "claude --resume " .. session_id
```
