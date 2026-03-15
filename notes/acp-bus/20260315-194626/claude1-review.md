# claude1 对 main 方案的逐条回应

## 问题1：统一启动方式 — 基本同意，补充一点

main 的方案对。但"主 agent 只有 chat 状态对象"这个表述需要更精确：

**主 agent 不是没有 client，而是 client 由外部注入。** 现在 `init.lua:171` 已经做了 `active_bus.main_client = client`，问题是这个注入逻辑散落在 `open_chat` 的回调里，而且 main 没有进入 `state.agents`。

建议的统一模型：
```
agent = {
  kind = "local" | "spawned",   -- 区分主/子
  client = Client | nil,         -- local 的 client 由外部注入
  status = "idle" | "streaming" | "error" | "disconnected",
  adapter_name = string,
  chat_buf = number | nil,       -- local 可以有（已有的 chat），spawned 必有
  streaming = bool,
  ...
}
```

`kind="local"` 意味着：不调 `client:start()`，不 spawn 进程，client 从 active_chats 里拿。其余行为（状态显示、消息路由、快照）和 spawned 完全一致。

## 问题3：主 agent 架构对等 — 完全同意

`_route()` 里 `elseif name == "main"` 是硬编码特例（bus.lua:297），应该消除。main 进入 `state.agents` 后，路由逻辑统一为：

```lua
function Bus:_route(content, from)
  for name in content:gmatch("@([%w_%-]+)") do
    if name ~= from and self.agents[name] then
      self:_send_to(name, content, from)  -- 统一入口
    end
  end
end
```

`_send_to()` 内部根据 `agent.kind` 分发：local 走 `_push_to_main` 逻辑，spawned 走 `send_to_agent` 逻辑。

## 问题2：chat 状态显示 — 同意方向，补充实现细节

状态机没问题。但不需要事件系统，bus 轮询就够了。原因：
- winbar 刷新已经是 `_refresh_winbar()` 主动调的
- 状态变化的触发点有限：prompt 开始/结束、on_exit、error
- 加事件系统是过度设计

**建议**：在 agent 结构里维护 `status` 字段，每次 `_refresh_winbar` 时直接读。状态更新点：
- `send_to_agent` 开始 → streaming
- prompt callback → idle
- on_exit → disconnected
- error → error

## 问题4：通道状态可见 — 不同意心跳方案

main 说的"adapter 层加心跳或连接状态检测"，ACP 协议没有 heartbeat，加心跳等于自己造协议扩展，成本高收益低。

**真正的问题是：现有状态没暴露给用户。** 具体来说：

1. `client.alive` 已经能反映进程是否存活（exit callback 设 false）
2. `_main_busy` / `_main_queue` 反映主 agent 通道是否阻塞
3. 但这些信息都没在 UI 上展示

**建议**：
- winbar 显示 main agent 状态（和子 agent 一样）：○离线 ● streaming ◉空闲
- winbar 显示队列深度：`main [queue:2]` 表示有 2 条消息排队
- `_push_to_main` 失败时已经有 `post("系统", "⚠ main 未连接")`，这就够了

如果以后确实需要更强的健康检查，可以在 `_push_to_main` 里加超时：prompt 超过 N 秒没回应就标 error。但现在不需要心跳。

## 问题5：快照持久化 — 同意，跟问题3联动

如果 main 进入 `state.agents`，store.lua 的 `save()` 不需要改——它已经遍历 `self.agents` 序列化了。只需确保 `kind="local"` 的 agent 序列化时记录 adapter_name 和 status，恢复时不尝试 spawn。

## 问题6：adapter 列表动态化 — 同意，最小改动

`adapter.lua` 已经有 `M.list()` 返回名字列表。最小改动：

```lua
-- adapter.lua 加 description 字段
local adapters = {
  claude = { name = "claude", description = "Claude Code (Anthropic)", ... },
  gemini = { name = "gemini", description = "Gemini CLI (Google)", ... },
  ...
}

function M.list_detailed()
  local result = {}
  for k, v in pairs(adapters) do
    result[#result+1] = { name = k, description = v.description }
  end
  return result
end
```

RPC 层 `acp.rpc.list_adapters()` 直接调 `adapter.list_detailed()`。

## 优先级建议

1. **问题1+3 一起做**（主 agent 对等化）— 这是架构基础，其他改进依赖它
2. **问题2**（状态显示）— 紧跟 1+3，因为 agent 统一了状态才有意义
3. **问题4**（通道可见性）— 利用 1+3 的成果，在 winbar 上展示
4. **问题5**（快照）— 1+3 解决后几乎自动完成
5. **问题6**（adapter 列表）— 独立小改动，随时可做
