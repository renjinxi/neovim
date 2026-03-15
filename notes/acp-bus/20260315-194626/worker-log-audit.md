# ACP 日志覆盖审计报告

## 审计范围

lua/acp/ 下 4 个核心文件，重点关注 open_headless 流程、on_update 转发、send_to_agent、bus 路由、agent 生命周期。

## 结果总览

| 文件 | 覆盖度 | 评级 |
|------|--------|------|
| client.lua | 全面 | ✅ 良好 |
| chat.lua | 零 | ❌ 缺失 |
| bus.lua | 部分 | ⚠️ 不足 |
| init.lua | 零 | ❌ 缺失 |

## 详细分析

### client.lua — ✅ 良好

已有日志：
- spawn：命令、PID、工作目录
- exit：退出码、持续时间
- handshake：时间戳、耗时
- prompt：请求摘要、耗时
- terminal 操作：write/resize
- stderr 输出
- 错误路径全覆盖

无需补充。

### chat.lua — ❌ 完全缺失

零日志。以下关键路径不可观测：

1. **open_headless 流程**：创建 buf、启动 client、无任何记录
2. **_start_client**：adapter 选择、spawn 参数、无记录
3. **on_ready 回调**：client 就绪、无记录
4. **_on_update**：收到更新、bus 转发、无记录
5. **on_exit**：进程退出、bus 通知、无记录
6. **_submit_input**：用户发送、bus 路由、无记录
7. **send**：prompt 发起/完成、无记录
8. **open/show/hide**：窗口生命周期、无记录

**影响**：open_headless 是子 agent 启动的唯一路径，完全不可调试。client.lua 有 spawn 日志，但 chat 层的 adapter 选择、bus 关联、on_ready 触发时机全部不可见。

### bus.lua — ⚠️ 部分覆盖

**已有日志**：
- `_push_to_main`：主 agent 交互（prompt 发起/完成/错误）
- `_on_agent_update`：tool_call 和 update 内容（有选择性记录）
- session 日志：`_write_session_log` 记录频道消息

**缺失日志**：

1. **add_agent**：创建 Chat、注册 agent、on_ready 回调 — 无记录
2. **_route**：路由决策（谁被 @mention、分发给谁）— 无记录
3. **_send_to**：发送决策（调用 send_to_agent 还是 _push_to_main）— 无记录
4. **send_to_agent**：开始发送、system_prompt 注入、无记录（只有 client.lua 的 prompt 日志）
5. **_cleanup_agents**：agent 清理过程 — 无记录
6. **save/restore_from_snapshot**：持久化操作 — 无记录
7. **agent 生命周期转换**：connecting→idle→streaming→disconnected 状态变化 — 无记录
8. **open/close**：频道创建/销毁 — 无记录

**影响**：多 agent 场景下，消息路由不可追踪。agent 上线/下线只能靠频道消息推断，无法定位卡在哪个环节。

### init.lua — ❌ 完全缺失

零日志。以下路径不可观测：

1. **open_chat**：adapter 选择、Chat 创建、toggle 决策
2. **open_bus**：Bus 创建、defer_fn 注入主 client
3. **on_ready 回调**：主 chat client 注册到 bus
4. **select_bus**：快照选择、恢复过程
5. **stop_all**：清理过程

**影响**：入口层完全静默，用户操作（命令调用、toggle）无法追踪。

## 建议优先级

1. **P0**：chat.lua open_headless + _start_client + on_ready — 子 agent 启动路径
2. **P0**：bus.lua add_agent + agent 生命周期转换 — agent 状态追踪
3. **P1**：bus.lua _route + send_to_agent — 消息路由可观测
4. **P1**：chat.lua _on_update bus 转发 — 双通道同步可观测
5. **P2**：init.lua 入口操作 — 调试便利性
6. **P2**：bus.lua save/restore — 持久化可观测
