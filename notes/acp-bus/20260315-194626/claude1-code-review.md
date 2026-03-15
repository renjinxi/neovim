# claude1 Code Review

## 总体评价

改动质量高，方案执行到位。5 个文件的改动和我们讨论的方案一致。以下是发现的 2 个问题和 1 个小建议。

## 问题1：winbar 对 local agent 的运行时状态检查缺失

bus.lua `_refresh_winbar()` 里，只对 `kind="spawned"` 做了 `client.alive` 运行时检查：

```lua
if agent.kind == "spawned" then
    if not agent.client or not agent.client.alive then
        status = "disconnected"
    elseif agent.streaming then
        status = "streaming"
    end
end
```

**问题**：如果 main 的 client 进程异常退出（Chat 的 Claude Code 挂了），`client.alive` 变 false，但 `main.status` 仍停在 "idle"——直到有人调 `_push_to_main` 才会被发现。

**修复**：运行时检查应对所有有 client 的 agent 生效：

```lua
-- 有 client 时，从 client 状态推导（不管 kind）
if agent.client then
    if not agent.client.alive then
        status = "disconnected"
    elseif agent.streaming then
        status = "streaming"
    end
elseif agent.kind == "local" then
    -- local 还没注入 client，保持存储的 status
else
    status = "disconnected"
end
```

## 问题2：list_agents() 返回值缺少 kind 和 status

现有 `list_agents()` 返回 `{name, alive, streaming}`，没有 `kind` 和 `status`。sub-agent 通过 `bus_agents()` RPC 调这个函数，看不到 agent 类型和状态。

**修复**：加两个字段：

```lua
result[#result + 1] = {
    name = name,
    kind = agent.kind or "spawned",
    status = agent.status or "idle",
    alive = agent.client and agent.client.alive or false,
    streaming = agent.streaming or false,
}
```

## 小建议：store.lua list 显示可过滤 local

`store.lua:list()` 遍历 agents 构建显示字符串时，main(local) 也会出现在列表里，显示为 `main(local)`。不影响功能，但用户看到可能困惑。可以在显示时跳过 kind="local" 的 agent，或改标签为 `main(主agent)`。非阻塞，可以后续处理。

## 检查清单确认

| 检查项 | 状态 |
|--------|------|
| main 注册到 agents 表 | ✅ bus:open() 末尾 |
| _route 统一路由 | ✅ 消除 main 硬编码 |
| _send_to 分发 | ✅ kind 判断正确 |
| winbar 显示 main | ✅ 排序 main 在前 |
| winbar 队列深度 | ✅ [queue:N] |
| status 更新点：streaming 开始 | ✅ send_to_agent + _push_to_main |
| status 更新点：streaming 结束 | ✅ prompt callback |
| status 更新点：exit | ✅ on_exit callback |
| status 更新点：error | ✅ _push_to_main alive 检查 |
| store save 包含 kind | ✅ |
| store restore 跳过 local | ✅ |
| init.lua 注入逻辑 | ✅ on_ready + defer_fn 都改了 |
| adapter description | ✅ 5 个都加了 |
| list_detailed() | ✅ |
| rpc.list_adapters | ✅ |
