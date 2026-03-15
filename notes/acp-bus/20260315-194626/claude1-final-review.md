# 最终 Review：ACP 频道系统重构

审核范围：chat.lua / bus.lua / init.lua / keymaps/modules/ai.lua
审核时间：2026-03-15

---

## 1. 功能完整性

### Main Agent 架构对等 ✅

- `Bus:open()` L134: main 注册为 `kind="local"`，统一进 agents 表
- `_send_to()` L354-362: 按 kind 分发，local → `_push_to_main`，spawned → `send_to_agent`
- `_route()` 不再有 main 硬编码分支
- `_refresh_winbar()` 统一展示所有 agent，main 排首位

### 统一 Chat 启动 ✅

- `add_agent()` L273-320: 通过 `Chat.new()` + `open_headless()` 启动 agent
- Chat 实例挂在 `agent.chat`，buffer 渲染由 Chat 负责
- bus 侧 `_on_agent_update()` 只管状态/活跃度/winbar，不碰 buffer
- `open_agent_buf()` L648: 通过 `agent.chat:show()` 打开 agent UI

### 命令精简 ✅

- `:Acp` 统一入口，子命令：chat/bus/list/restore/stop/cli
- Tab 补全覆盖子命令 + adapter 名 + agent 名
- 无参数 toggle：优先 bus，其次 chat

### 原生 CLI Resume ✅

- `open_native_cli()` L154-194: 通过 `claude --resume SESSION_ID` 打开
- 只支持 claude/c1/c2
- 正确注入 ANTHROPIC_ 环境变量

### 日志覆盖 ✅

- chat.lua: 7 条日志（open_headless, _start_client×3, on_exit, on_ready, _submit_input, _on_update）
- bus.lua: 6 条日志（add_agent×2, _route, send_to_agent×3）
- 日志格式统一：`%H:%M:%S [LEVEL] module: msg`

### 快捷键 ✅

- keymaps/modules/ai.lua: 终端 AI 快捷键，与 ACP 无关
- ACP 快捷键应在 all.lua 中定义（`<A-u>` toggle、`<A-i>` list）——需确认 all.lua 中实际注册情况

---

## 2. 一致性

### 命名 ✅

- `kind` 一致：`"local"` / `"spawned"`
- `status` 一致：`"connecting"` / `"idle"` / `"streaming"` / `"disconnected"` / `"error"`
- agent 字段命名统一：`client` / `chat` / `status` / `streaming` / `adapter_name`

### 日志格式 ✅

- chat.lua 和 bus.lua 的 log 函数签名、格式、输出目录一致
- 日志级别使用规范：ERROR(失败) / WARN(离线) / INFO(生命周期) / DEBUG(路由/转发)

### 错误处理 ⚠️ 一处风格不一致

- `_push_to_main` L369: `main.client` nil 检查 → WARN + post 通知 ✅
- `_push_to_main` L374: `main.client.alive` 检查 → WARN + post + 刷 winbar ✅
- `send_to_agent` L459: 合并检查 `!agent || !client || !alive` → WARN + post ✅
- **不一致**：`send_to_agent` 检查 alive 时没有主动设置 `status="disconnected"`，而 `_push_to_main` L376 会设置。建议 `send_to_agent` 也加上 `agent.status = "disconnected"`。

---

## 3. 边界情况

### Nil Check ✅

- `_on_agent_update` L552-565: params/update/kind/agent 四重 nil guard
- `_on_update` L330-338: params/update/kind 三重 nil guard
- `_refresh_winbar` L148/452: win validity check
- `_notify_main_chat` L438: pcall require，chats 为空时安全退出
- `list_agents` L674: `agent.kind or "spawned"`, `agent.status or "idle"` 带默认值

### 进程退出 ✅

- chat.lua `on_exit` L222-237: 设 bus agent status="disconnected"，通知频道，刷 winbar
- BufWipeout L109/180: client:stop() + pcall 保护
- VimLeavePre L121/192: 清理保护（chat 和 headless 都有）
- bus VimLeavePre L118: 保存快照 + _cleanup_agents

### 窗口已关 ✅

- `_scroll_to_bottom` / `_refresh_winbar` 都有 win validity check
- `_setup_input_autoresize` callback 内有 input_win validity check
- `show()` 检查 buf validity，失败返回 false

### Streaming 同步 ✅

- `send_to_agent` L474-483: 发送前设 `agent.chat.streaming = true`
- `send_to_agent` L498-503: 完成后设 `agent.chat.streaming = false`
- 两端都刷 chat winbar

---

## 4. Cleanup 路径

| 场景 | 路径 | 覆盖 |
|------|------|------|
| 用户关 nvim | VimLeavePre → save_snapshot + _cleanup_agents | ✅ |
| 用户 :Acp stop | M.stop_all → chat:close + bus:close | ✅ |
| Bus buffer 被 wipe | BufWipeout → _cleanup_agents | ✅ |
| Chat buffer 被 wipe | BufWipeout → client:stop | ✅ |
| Headless Chat buffer 被 wipe | BufWipeout → client:stop | ✅ |
| Headless Chat nvim 退出 | VimLeavePre → client:stop | ✅ |
| agent 进程自行退出 | on_exit → status=disconnected + post | ✅ |

### ⚠️ 潜在问题

1. **Bus close 后 chat VimLeavePre 重复清理**：Bus._cleanup_agents 已 stop 所有 client，但 chat 的 VimLeavePre autocmd 还在，会再次 pcall stop。不会崩，但存在冗余。无害。

2. **_notify_main_chat 循环引用**：bus.lua L438 `pcall(require, "acp.init")` 访问 init._active_chats()。init.lua require bus.lua。Lua 的 require 缓存避免了无限循环，但设计上 bus 反向依赖 init 不够干净。当前可接受，M2 可考虑注入回调消除。

3. **open_bus defer_fn 500ms 竞态**：init.lua L231 用 `vim.defer_fn(fn, 500)` 注入 main client。如果 chat client 启动超过 500ms（首次 handshake 可能较慢），main 将不会被注入。chat.on_ready 回调 L213 是更可靠的路径，defer_fn 是 fallback。两者都设置同一字段，不冲突。建议：如果 on_ready 已覆盖，defer_fn 可以删掉或加大延迟。

4. **adapter_name 匹配**：init.lua L199 `name:match("^" .. adapter_name .. "_")`，如果 adapter_name 含 Lua 模式特殊字符（如 `-`），会导致匹配异常。当前 adapter 名都是纯字母，暂无问题。

---

## 5. 总结

重构质量高，6 个方案全部落地。核心改动点（main 对等、统一 Chat 启动、命令精简）设计合理，实现到位。日志覆盖达到 P0+P1 级别。

**需要 fix 的**：
1. `send_to_agent` L459 检查 alive 失败时加 `agent.status = "disconnected"` 保持一致

**建议改进（非阻塞，后续处理）**：
1. `open_bus` defer_fn 500ms 在 on_ready 已覆盖后冗余，可删除
2. bus → init 反向依赖可在 M2 用回调注入消除
3. adapter_name 匹配用 `vim.startswith` 替代 `string.match` 更安全
