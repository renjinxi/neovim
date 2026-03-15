# 2026-03-15 频道持久化讨论记录

## 参与者
- main (Claude Code, 协调者)
- codex (OpenAI Codex, 分析协议层)
- gemini (未成功回复，#3 认证问题可能未解决)
- dev (c1, 派了任务但没干活)
- dev2 (c2, 派了任务但遇到 bus bug 中断)

## 用户原始需求

### 需求 1 — 实时状态监控
> 还有一个其实是实时 我其实有的时候就是只是想去看一下他到底有没有在干活

### 需求 2 — session ID 持久化
> acp buffer 记录 session id，方便重启继续频道

### 需求 3 — session ID 调度
> acp 通过 session id 可以很方便的调度起原来的 cli 的对话 原生的

## Codex 分析结论

### 协议层
- ACP 没有原生 idle/working status 字段
- `session/update` 类型：agent_message_chunk, tool_call, tool_call_update, plan, available_commands_update
- 稳定能力是 `session/load`，不是 `session/resume`
- Claude 和 Gemini 都声明了 `loadSession=true`
- Claude 额外有 `sessionCapabilities.resume`，但非通用

### 状态监控方案
- bus_agents() 现有 alive + streaming 基本够用
- streaming 语义上是 busy（send_to_agent 置 true，prompt 完成置 false）
- 短期方案：`status = !alive ? offline : (streaming ? busy : idle)`

### 持久化方案
用户澄清后的理解：**以频道为单位恢复**，不是单个 session。
- 只记频道里有哪些 agent + adapter 类型 + session_id + 聊天历史
- 不记认证、cwd、配置，这些 adapter 自己处理
- 恢复流程：spawn adapter → session/load(sessionId)

## 最终实现方案（已写入代码）

### 存储
```
~/.local/state/nvim/acp-channels/{cwd编码}/{channel_id}.json
```
cwd 编码：去掉 `/` 开头，`/` 替换为 `-`

### 快照数据
```json
{
  "version": 1,
  "channel_id": "20260315-143000",
  "saved_at": "...",
  "cwd": "...",
  "agents": [{"name": "xxx", "adapter": "c1", "session_id": "..."}],
  "history": [{"from": "main", "content": "...", "timestamp": 123}]
}
```

### 命令
- `:AcpBus` — 始终新建频道（不变）
- `:AcpBusSelect` — 选择恢复历史频道

### M0 限制
- 恢复时 agent 走 session/new（不依赖 session/load）
- session/load 等后续验证通过再加

### 代码改动
- 新建 `lua/acp/store.lua` — 持久化逻辑
- 修改 `lua/acp/bus.lua` — channel_id/cwd/adapter_name 跟踪，save_snapshot/restore_from_snapshot
- 修改 `lua/acp/init.lua` — :AcpBusSelect 命令

## 遇到的 Bug

### _append_agent_system 换行崩溃
`bus.lua:456` 原来直接 `{ "*" .. text .. "*" }` 传给 `nvim_buf_set_lines`，text 含换行时报错。
修复：先 `vim.split` 再传。

### Agent 回复失败
上述 bug 导致 tool_call_update 渲染时报错，中断了流式处理，agent 的回复无法通过 bash → nvim --remote-expr 成功发回频道。

## 待验证
- [ ] session/load 是否真能用（重启后验证）
- [ ] Gemini 认证问题（#3）
- [ ] 频道恢复完整流程测试
