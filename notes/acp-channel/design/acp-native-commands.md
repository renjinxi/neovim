# #20 ACP 协议原生命令 + Chat 输入框命令系统

by claude2 | 2026-03-16

---

## A. ACP 协议调研

### A.1 当前 client.lua 已实现的 method

| Method | 类型 | 用途 |
|--------|------|------|
| `initialize` | request (sync) | 握手：交换 capabilities |
| `authenticate` | request (sync) | 认证（gemini 需要） |
| `session/new` | request (sync) | 创建新会话 |
| `session/prompt` | request (async) | 发送用户消息 |
| `session/cancel` | notification | 取消当前 streaming |
| `session/update` | notification (收) | agent 流式推送 |
| `session/request_permission` | request (收) | agent 请求权限 |
| `fs/read_text_file` | request (收) | agent 读文件 |
| `fs/write_text_file` | request (收) | agent 写文件 |
| `terminal/create` | request (收) | agent 创建子进程 |
| `terminal/output` | request (收) | agent 读终端输出 |
| `terminal/wait_for_exit` | request (收) | agent 等待进程退出 |
| `terminal/kill` | request (收) | agent 杀进程 |
| `terminal/release` | request (收) | agent 释放终端 |

### A.2 ACP JSON Schema 定义的全部 method

来源：`codecompanion.nvim/.codecompanion/acp/acp_json_schema.json`

**Client → Agent (request):**
| Method | Schema 类型 | 说明 |
|--------|------------|------|
| `initialize` | InitializeRequest | ✅ 已实现 |
| `authenticate` | AuthenticateRequest | ✅ 已实现 |
| `session/new` | NewSessionRequest | ✅ 已实现 |
| `session/load` | LoadSessionRequest | ❌ 未实现 |
| `session/prompt` | PromptRequest | ✅ 已实现 |

**Client → Agent (notification):**
| Method | Schema 类型 | 说明 |
|--------|------------|------|
| `session/cancel` | CancelNotification | ✅ 已实现 |

**Agent → Client (request):**
| Method | Schema 类型 | 说明 |
|--------|------------|------|
| `fs/read_text_file` | ReadTextFileRequest | ✅ 已实现 |
| `fs/write_text_file` | WriteTextFileRequest | ✅ 已实现 |
| `session/request_permission` | RequestPermissionRequest | ✅ 已实现 |

**Agent → Client (notification):**
| Method | Schema 类型 | 说明 |
|--------|------------|------|
| `session/update` | SessionNotification | ✅ 已实现 |

### A.3 codecompanion 额外支持的 method（非 Schema 标准）

| Method | 来源 | 说明 |
|--------|------|------|
| `session/set_mode` | codecompanion methods.lua | Claude 扩展：切换 plan/code/ask 等模式 |
| `session/set_model` | codecompanion methods.lua | Claude 扩展：运行时切换模型 |
| `session/load` | Schema 标准 | 加载已有 session（需 `loadSession=true` capability） |

### A.4 Schema 中不存在的 method

以下命令**不在 ACP 协议中**：
- ❌ `session/clear` — 无此 method
- ❌ `session/compact` — 无此 method
- ❌ `session/exit` — 无此 method

**关键发现**：ACP 协议没有 clear/compact/exit 概念。这些需要客户端自行实现。

### A.5 session/load 详情

```
LoadSessionRequest:
  sessionId: string (必填)
  cwd: string (必填)
  mcpServers: McpServer[] (必填)
```

前置条件：`initialize` 返回的 `agentCapabilities.loadSession == true`

codecompanion 实现逻辑（`acp/init.lua` L208-248）：
1. 检查 `loadSession` capability
2. 如果有旧 sessionId 且支持 load → 发 `session/load`
3. 如果 load 失败 → fallback 到 `session/new`

### A.6 session/set_mode 和 session/set_model

codecompanion 的实现（非 Schema 标准，Claude 扩展）：
- `session/new` 返回 `modes` 和 `models` 列表
- `session/set_mode` 切换模式（plan/code/ask 等）
- `session/set_model` 切换模型（opus/sonnet 等）

---

## B. Chat 输入框命令系统设计

### B.1 命令列表

| 命令 | 实现方式 | 说明 |
|------|---------|------|
| `/compact` | 断开 + session/load 重连 | 利用 agent 内部 compact 机制 |
| `/clear` | 断开 + session/new 重连 | 全新会话，清空历史 |
| `/exit` | client:stop() | 关闭进程 |
| `/status` | 本地查询 | 显示 client 状态 |
| `/mode [name]` | session/set_mode | Claude 扩展 |
| `/model [name]` | session/set_model | Claude 扩展 |
| `/cancel` | session/cancel | 取消当前 streaming（等价于 `<C-c>`） |
| `/load [session_id]` | session/load | 加载指定 session |

### B.2 /compact 实现方案

ACP 没有 compact method。方案：

**方案 A：重连 session/load**
```
1. 保存当前 session_id
2. client:stop()
3. 重新 spawn + initialize + authenticate
4. session/load(sessionId=旧id)
```
利用 agent 侧的 session 持久化。load 时 agent 内部可能自动 compact。

**方案 B：发特殊 prompt**
```
client:prompt("/compact", on_done)
```
Claude Code CLI 内部支持 `/compact` 命令。通过 ACP prompt 发送可能触发。

**建议**：先试方案 B（简单），不行再用方案 A。

### B.3 /clear 实现方案

```
1. client:stop()
2. 重新 spawn + initialize + authenticate
3. session/new (新 session)
4. 更新 Chat.client / Chat.session_id
```

### B.4 拦截位置

```
Chat._submit_input()
  ├─ if text:match("^/") then
  │    self:_handle_command(text)
  │    return
  ├─ if self.on_submit then  -- 频道模式
  │    self.on_submit(text)
  └─ else
       self:send(text)

ChannelView._submit_input()
  ├─ if text:match("^/") then
  │    self.channel:handle_command(text)  -- 频道级命令
  │    return
  └─ self.channel:post("你", text)
```

**两层拦截**：
1. **Chat._submit_input** — `/compact`、`/clear`、`/exit`、`/status`、`/mode`、`/model` 在此处理（作用于当前 Chat 的 client）
2. **ChannelView._submit_input** — 频道级命令（`/add`、`/stop`、`/list` 等）在此处理

命令以 `/` 开头，和普通消息（可能包含 `@mention`）区分。

### B.5 Chat 命令处理器

```lua
function Chat:_handle_command(text)
    local cmd, args = text:match("^/(%S+)%s*(.*)")
    if not cmd then return end

    if cmd == "status" then
        self:_append_system(self:_format_status())
    elseif cmd == "cancel" then
        self:cancel()
    elseif cmd == "exit" then
        if self.client then self.client:stop() end
        self:_append_system("已退出")
    elseif cmd == "clear" then
        self:_reconnect({ fresh = true })
    elseif cmd == "compact" then
        self:_reconnect({ load = true })
        -- 或 self:send("/compact")
    elseif cmd == "mode" then
        self:_set_mode(args)
    elseif cmd == "model" then
        self:_set_model(args)
    else
        self:_append_system("未知命令: /" .. cmd)
    end
end
```

### B.6 频道级命令

ChannelView 层的命令，作用于整个频道：

| 命令 | 说明 |
|------|------|
| `/add <adapter> [name]` | 添加 agent |
| `/stop <name>` | 停止指定 agent |
| `/list` | 列出 agent 状态 |
| `/open <name>` | 打开 agent 的 Chat 窗口 |

这些在 ChannelView._submit_input 拦截，delegate 给 Channel 的公有方法。

### B.7 client.lua 需新增的方法

```lua
--- session/load：加载已有 session
function Client:load_session(session_id, opts)
    opts = opts or {}
    local result, err = self:_request_sync("session/load", {
        sessionId = session_id,
        cwd = opts.cwd or vim.fn.getcwd(),
        mcpServers = opts.mcpServers or {},
    }, 30000)
    if err then return nil, err end
    return result
end

--- session/set_mode（Claude 扩展）
function Client:set_mode(mode_id)
    return self:_request_sync("session/set_mode", {
        sessionId = self.session_id,
        modeId = mode_id,
    }, 5000)
end

--- session/set_model（Claude 扩展）
function Client:set_model(model_id)
    return self:_request_sync("session/set_model", {
        sessionId = self.session_id,
        modelId = model_id,
    }, 5000)
end
```

### B.8 Chat 重连方法

```lua
--- 重连：stop + 重新 start
function Chat:_reconnect(opts)
    opts = opts or {}
    local old_session_id = self.client and self.client.session_id
    local load = opts.load and old_session_id

    -- 停止旧进程
    if self.client then
        self.client:stop()
        self.client = nil
    end

    self:_append_system("重连中...")
    self.streaming = false

    -- 重新启动（_start_client 会创建新 client + 握手）
    if load then
        -- 需要改造 _start_client 支持 load 模式
        self._pending_load_session = old_session_id
    end
    vim.schedule(function()
        self:_start_client()
    end)
end
```

---

## C. 优先级建议

### P0 — 最小可用（M1 阶段）
1. Chat `/status` — 本地，无 RPC
2. Chat `/cancel` — 已有 session/cancel
3. Chat `/exit` — client:stop()
4. ChannelView `/add` `/stop` `/list` `/open` — 频道操作

### P1 — 核心体验
5. Chat `/clear` — 断开 + session/new
6. Chat `/compact` — 先试 prompt("/compact")，再考虑 session/load
7. client.lua `session/load` 实现

### P2 — Claude 扩展
8. Chat `/mode` — session/set_mode
9. Chat `/model` — session/set_model
10. session/new 返回值解析（modes/models 列表）
