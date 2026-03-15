# ACP 频道系统 Final Code Review

by claude2 | 2026-03-15

审查范围：今日全部改动（init.lua, chat.lua, bus.lua, client.lua, keymaps, store.lua）

---

## 1. 功能完整性 ✅

### 1.1 命令合并 `:Acp` — 完整
- 6 个子命令：chat/bus/list/restore/stop/cli + 无参 toggle
- 补全逻辑正确：第一层补子命令，第二层按子命令补 adapter/agent
- cli 补全过滤 kind="local"，正确

### 1.2 Chat headless 模式 — 完整
- open_headless() 创建 buffer + client，不创建窗口
- keymaps 绑在 buffer 上，show() 后自动生效
- bus 模式下 _submit_input 走频道路由而非直接 send
- _on_update 转发给 bus（双写：Chat buffer + bus 状态）

### 1.3 Bus agent 管理重构 — 完整
- add_agent 改为 Chat.open_headless 启动，取代原来的裸 client
- agent 有完整生命周期：connecting → idle → streaming → idle/disconnected
- winbar 实时显示状态 + 活动提示

### 1.4 频道持久化 — 完整
- VimLeavePre 自动保存，`:Acp restore` 恢复
- 恢复时重启 agent（新 session，不依赖 session/load）
- 历史消息回填到 buffer

### 1.5 快捷键精简 — 完整
- `<A-u>` toggle（全模式），`<A-i>` picker（全模式）
- 旧的 `<leader>ai*` 6 个快捷键已删除
- ai.lua 补了 claude proxy env

---

## 2. BUG 和边界问题

### 🔴 BUG-1: _push_to_main on_update 劫持后 chat 渲染断裂

**bus.lua:402-408**
```lua
main.client.on_update = function(params)
    if orig_on_update then orig_on_update(params) end
    -- ...收集 stream_buf
end
```

`orig_on_update` 保存的是 `main.client.on_update`，但 main client 的 on_update 是在 `client:start()` 时设置的 `opts.on_update`。这个回调链是：

- client._handle_notification → client.on_update（Chat._on_update）
- _push_to_main 临时替换 client.on_update → 收集 stream_buf + 调原 on_update

**问题**：如果 _push_to_main 嵌套调用（队列处理时），orig_on_update 会被覆盖为上一次的劫持函数。但实际代码里 _main_busy 锁保证了不会嵌套，所以**当前不会触发**。

**但还有一个问题**：main client 是从 active_chats 注入的，它的 on_update 是 Chat:_on_update。_push_to_main 替换了 client.on_update，如果 prompt 期间用户在 Chat 输入框手动发消息（Chat:send），Chat:send 调 client:prompt，此时 on_update 已被劫持。不过 Chat:send 有 `if self.streaming then return` 保护，而 _push_to_main 设置了 main.status="streaming"，但 **Chat.streaming 没有同步设为 true**。

**修复建议**：_push_to_main 开始时设 `main.streaming = true`，对应的主 Chat 也设 streaming=true。

### 🔴 BUG-2: open_native_cli adapter_config.env 包含完整进程环境

**init.lua:180-191**
```lua
local adapter_config = require("acp.adapter").get(adapter_name, {})
local env_parts = {}
if adapter_config.env then
    for k, v in pairs(adapter_config.env) do
        if k:match("^ANTHROPIC_") then
            env_parts[#env_parts + 1] = k .. "=" .. vim.fn.shellescape(v)
        end
    end
end
```

adapter.get() 调了 `terminal.get_env(extra_env)`，返回的是合并后的完整 env。但这里只过滤 ANTHROPIC_ 前缀，所以功能上是正确的。

**不过**：adapter.get() 的第二个参数 `opts={}` 没传 api_num，所以 c1/c2 的 get_env 不走 api_num 分支，而是直接从环境变量名拿。看 adapter 定义，c1/c2 的 get_env 不依赖 opts.api_num，直接读 CLAUDE_API1_*/CLAUDE_API2_*。**没问题**。

### 🟡 WARN-1: Bus:show() 重复注册 _setup_input_autoresize

**bus.lua:251-252, chat.lua:519**

每次 show() 都调 _setup_input_autoresize()，注册一个新的 autocmd。多次 hide/show 后同一个 input_buf 上会叠加多个 TextChanged 回调。

**影响**：功能无异常（多个回调做同样的事），但有微量性能浪费。

**修复**：用 augroup 去重，或加标记位跳过重复注册。

### 🟡 WARN-2: _notify_main_chat 循环引用 acp.init

**bus.lua:438**
```lua
local ok, init = pcall(require, "acp.init")
```

bus.lua require acp.init，acp.init require acp.bus。Lua require 有循环依赖保护（返回部分加载的 module），但 _notify_main_chat 是运行时调用不是加载时调用，所以**实际没问题**。不过这个跨模块引用让依赖方向不够清晰。

**可接受**，已用 pcall 保护。

### 🟡 WARN-3: store.lua save 时 messages 可能含不可序列化数据

**store.lua:39**
```lua
history = bus.messages,
```

bus.messages 是 `{from, content, timestamp}` 的简单 table，都是字符串和数字，**可以序列化**。没问题。

### 🟡 WARN-4: restore_from_snapshot channel_id 覆盖

**bus.lua:697**
```lua
self.channel_id = snapshot.channel_id
```

但 Bus.new() 已经在 open() 里用 channel_id 初始化了 session_dir（`LOG_DIR/bus-{channel_id}`）。restore 改了 channel_id 但没更新 session_dir。

**影响**：恢复后的新日志写到新的 session_dir，不是旧频道的 session_dir。这其实是合理行为（旧日志保留，新日志单独记录），但可能让用户困惑。

---

## 3. Cleanup 路径检查

### ✅ Chat 清理
- BufWipeout: stop client ✓
- VimLeavePre: stop client ✓
- close(): stop client + close win + delete buf ✓
- hide(): 只关窗口，保留 client ✓

### ✅ Bus 清理
- BufWipeout: _cleanup_agents ✓
- VimLeavePre: save_snapshot + _cleanup_agents ✓
- close(): save_snapshot + _cleanup_agents + close win + delete buf ✓
- hide(): 只关窗口 ✓

### ✅ Client 清理
- stop(): kill terminals + close pipes + sigterm/sigkill ✓
- exit callback: 清理 pending 回调 ✓ （今日新增，关键修复）

### 🟡 遗漏：stop_all 不清理 agent chat 的 buffer

**init.lua:335-343**
```lua
function M.stop_all()
    for name, chat in pairs(active_chats) do
        pcall(function() chat:close() end)
        active_chats[name] = nil
    end
    if active_bus then
        pcall(function() active_bus:close() end)
        active_bus = nil
    end
end
```

active_bus:close() → _cleanup_agents 通过 `agent.chat.client:stop()` 停进程，但不调 `agent.chat:close()` 来清理 buffer。agent.chat 的 buf 和 input_buf 变成孤儿 buffer。

**修复**：_cleanup_agents 里也调 `agent.chat:close()`。

### 🟡 遗漏：select_bus 恢复时旧 bus 的 agent chat buffer 未清理

**init.lua:273**
```lua
pcall(function() active_bus:close() end)
```

close() → _cleanup_agents → stop client，但同上，agent.chat 的 buffer 未清理。

---

## 4. 日志覆盖度

### ✅ 到位
- client.lua: spawn/handshake/prompt/terminal/exit 全链路 ✓
- chat.lua: open_headless/_start_client/on_exit/on_ready/_submit_input/_on_update ✓
- bus.lua: add_agent/ready/_route/_push_to_main/send_to_agent/done/error ✓
- rpc.lua: bus_post_file ✓

### 🟡 缺失
- **init.lua 无日志**：toggle_or_start/open_bus/open_chat/stop_all 没有日志。出问题时不知道用户执行了什么命令。
- **store.lua 无日志**：save/load/list 无日志，恢复失败时难定位。
- **Bus:hide/show 无日志**：不知道窗口何时开关。

---

## 5. 其他观察

### 5.1 keymaps ai.lua proxy 改动 — 正确
claude provider 的 build 函数加了 CLAUDE_PROXY 读取，和 adapter.lua 的 get_proxy_env 对齐。

### 5.2 client.lua pending 清理 — 关键修复
进程退出时清理所有 pending 回调，防止调用方永远卡住。这修复了一个严重问题。

### 5.3 client.lua _env_list 继承环境 — 关键修复
原来只传 adapter.env，子进程缺 PATH 等基础变量。现在继承完整环境再覆盖。

---

## 总结

| 级别 | 数量 | 说明 |
|------|------|------|
| 🔴 BUG | 1 | _push_to_main 期间主 Chat streaming 状态未同步 |
| 🟡 WARN | 5 | autocmd 叠加、cleanup 不完整、日志缺失 |
| ✅ PASS | 5 大功能 | 命令合并、headless Chat、winbar、持久化、快捷键 |

**整体评价**：改动量大（~800 行 diff），架构方向正确（Chat 统一管理 agent buffer，bus 只管状态和路由）。主要问题是 cleanup 路径不够彻底，建议下次集中补。
