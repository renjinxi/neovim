# claude1 Review: 统一 Chat 启动

## 总体评价

实现完整，和方案一致。on_update 双通道、send_to_agent streaming 同步、_submit_input bus 路由、_append_agent_* 删除、open_agent_buf 改用 chat:show() 全部到位。发现 1 个问题和 2 个小问题。

## 问题1（需修复）：open_headless 缺少 VimLeavePre 清理

chat.lua open() 有 VimLeavePre autocmd（line 109-118），但 open_headless()（line 126-182）没有。headless 启动的子 agent 在 nvim 退出时不会走 Chat 的清理路径。

虽然 bus 的 VimLeavePre 会调 `_cleanup_agents()`，但如果 bus 没有活跃（比如已经 close 了但 Chat 进程还在），子 agent 进程可能泄漏。

**修复**：open_headless 里加 VimLeavePre autocmd，和 open() 保持一致：

```lua
-- open_headless 里，BufWipeout 之后加
vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("acp_chat_cleanup_" .. self.buf, { clear = true }),
    once = true,
    callback = function()
        if self.client then
            pcall(function() self.client:stop() end)
        end
    end,
})
```

## 小问题2：send_to_agent user 消息双写

bus.lua send_to_agent line 477-480：

```lua
if agent.chat then
    agent.chat:_append_role("You", text)
end
```

但 send_to_agent 调 `agent.client:prompt(payload)` 后，on_update 会触发 Chat._on_update。Chat._on_update 不会写 user 消息（它只处理 agent 回复），所以这里手动写是正确的。

不过要注意：如果以后 Chat.send() 也被调（比如用户通过 Chat 输入框直接发），send() 里也会 `_append_role("You", text)`，然后 bus 路由又会到 send_to_agent 再写一次。

**当前不会触发**：因为 _submit_input bus 路由走的是 `self.bus:post("你", content)`，不走 Chat.send()。但需要注意以后改动时别打破这个假设。不阻塞。

## 小问题3：_cleanup_agents 通过 chat.client 清理

bus.lua line 262：

```lua
local client = agent.chat and agent.chat.client or agent.client
```

这是正确的——spawned agent 的 client 在 Chat 里。但 `agent.client` 和 `agent.chat.client` 是同一个对象（on_ready 里赋值的），所以 `or agent.client` 是冗余的。不影响正确性，只是语义上 `agent.chat.client` 已经够了。非阻塞。

## 检查清单

| 检查项 | 状态 |
|--------|------|
| open_headless 创建 buf + input_buf | ✅ |
| open_headless 设置 keymaps | ✅ |
| open_headless BufWipeout 保护 | ✅ |
| open_headless VimLeavePre 清理 | ❌ 缺失 |
| on_update 转发给 bus | ✅ chat.lua:321-323 |
| on_exit bus 通知 | ✅ chat.lua:198-206 |
| add_agent 改用 Chat | ✅ bus.lua:273-317 |
| agents 表有 chat 引用 | ✅ bus.lua:293 |
| agents 表有 chat_buf | ✅ bus.lua:315 |
| _on_agent_update 不操作 buffer | ✅ 只管状态/日志 |
| _append_agent_role/chunk/system 已删 | ✅ |
| send_to_agent 同步 chat.streaming | ✅ bus.lua:470-474 + 490-493 |
| send_to_agent 写 user 消息到 Chat | ✅ bus.lua:478-480 |
| _submit_input bus 路由 | ✅ chat.lua:258-264 |
| open_agent_buf 改用 chat:show() | ✅ bus.lua:640 |
| _cleanup_agents 通过 chat 清理 | ✅ bus.lua:262 |
| "connecting" 中间状态 + winbar 图标 | ✅ bus.lua:171-177（额外加分） |
| init.lua AcpAgents 适配 chat | ✅ 用 agent.chat 判断可见性 |

## 额外观察

worker 做了一个方案里没有的改进：add_agent 先注册 `status="connecting"`，winbar 显示 ◌ 图标。这很好，client 启动有延迟，用户能看到中间状态。
