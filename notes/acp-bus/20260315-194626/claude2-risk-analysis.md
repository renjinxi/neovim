# ACP 频道系统风险分析

by claude2 | 2026-03-15

---

## 一、首次使用体验的坑

### 1.1 开频道流程不直观
`:Acp bus claude agent1` 才能开频道+加agent，但用户第一反应是 `:Acp` 直接开。
而 `:Acp` 无参数会 toggle_or_start → open_chat("claude")，开的是 1v1 chat 不是频道。

**断裂点**：用户想用频道但不知道要加子命令，开了 chat 后不知道怎么切到频道模式。

### 1.2 agent_name 默认规则隐晦
`:Acp bus claude` → agent_name 默认 "claude-1"，但 `:Acp bus c1` → "c1-1"。
用户不知道 agent 叫什么名字，发消息时 @谁？

**建议**：添加 agent 成功后频道 post 包含实际 agent_name。

### 1.3 main agent 的 500ms defer 竞态
`open_bus` 里用 `vim.defer_fn(500)` 等 main client 就绪。如果 chat client 握手超过 500ms（网络慢），main 就注册不上。用户看到"main 未连接"但不知道为什么。

**风险等级**：中。国内代理网络下握手可能 2-3 秒。

---

## 二、错误恢复的断裂

### 2.1 agent 进程崩溃后无法重启
agent 退出后 status 变 "disconnected"，但没有重启机制。用户只能 `:Acp stop` 全部关掉重来。

**缺失**：需要 `:Acp restart <agent_name>` 或自动重连。

### 2.2 main client 断开后频道瘫痪
main client 断开 → `_push_to_main` 发"⚠ main 未连接"，但子 agent 继续往 @main 发消息 → 全部丢进"未送达"。频道变成单向广播，无法恢复。

**断裂点**：没有重新绑定 main client 的入口。如果用户重新 `:Acp chat claude` 开了新 chat，active_bus.agents["main"].client 不会自动更新（除非走 on_ready 且 active_bus 存在）。

### 2.3 store.lua 恢复不带上下文
restore_from_snapshot 重启 agent 走 session/new，agent 没有之前的对话历史。恢复的"频道"只是 buffer 里有历史消息，agent 实际是全新的。

**用户期望 vs 现实差距大**：以为"恢复"是继续，实际是重开。

---

## 三、多 agent 场景边界

### 3.1 _push_to_main 串行队列无超时
如果 main 的 prompt 卡住（比如在跑长任务），队列里的消息永远出不来。没有超时机制，也没有让用户手动清队列的命令。

**风险**：main 卡 5 分钟 → 其他 3 个 agent 的消息全部排队 → 频道看起来"死了"。

### 3.2 agent 回复自动 post 可能触发循环
agent A @main → main 回复带 @A → 路由回 A → A 又 @main...
虽然 _route 跳过 from==name，但 main 的回复 from="main"，如果内容里 @A，就会再推给 A。

**风险等级**：高。目前没有循环检测或深度限制。一旦触发，两个 agent 互相 @，直到 token 耗尽。

### 3.3 同名 agent 冲突
`:Acp bus claude agent1` 两次 → add_agent 覆盖 self.agents["agent1"]，第一个进程变孤儿（没人引用，也不会被 _cleanup_agents 清理）。

### 3.4 多 agent 同时写同一文件
两个 agent 的 fs/write_text_file 请求可能交叉，vim.schedule 不保证原子性。buffer 内容可能损坏。

---

## 四、UI/UX 问题

### 4.1 频道 buffer 不可搜索
buftype=nofile + modifiable=false → 用户想搜历史消息只能肉眼滚。session_write 写的日志在 logs/ 目录，不在用户期望的位置。

### 4.2 show/hide 反复开关会累积 vsplit
每次 show() 都 `botright vsplit`，如果用户反复 toggle，窗口不会复用而是新开。虽然 hide 先关窗口，但如果有其他插件干预窗口布局，可能出现多个 bus 窗口。

### 4.3 input_buf keymaps 在 show() 后不重新绑定
open() 和 open_headless() 绑了 `<CR>` 和 `<C-c>`，但 show() 没有重新绑。如果 input_buf 被 wipeout 后重新创建，keymaps 就丢了。

**实际看代码**：input_buf 是 bufhidden=hide 不会 wipeout，所以 keymaps 应该还在。但 Bus:show() 没有重新绑 `<CR>`，如果 input_buf 出问题就断了。

---

## 五、安全/资源问题

### 5.1 --yolo 模式默认开启
所有 claude adapter 都带 `--yolo`，子 agent 可以不经确认执行任何 bash 命令。频道场景下 agent 被提示注入的风险更高（消息来源多）。

### 5.2 terminal 子进程没有资源限制
outputByteLimit 默认 1MB，但没有进程数量限制。一个 agent 可以 terminal/create 开几十个子进程。

### 5.3 日志文件无限增长
acp-client.log、acp-bus.log、acp-rpc.log 都是 append 模式，没有 rotate 机制。长期使用会占满磁盘。

---

## 六、优先修复建议

| 优先级 | 问题 | 建议 |
|--------|------|------|
| P0 | 循环路由 (#3.2) | 加消息深度计数器，超过 3 层停止路由 |
| P0 | main 串行队列无超时 (#3.1) | 加 60s 超时，超时后 post 错误 + 弹出队列 |
| P1 | agent 重启机制 (#2.1) | `:Acp restart <name>` |
| P1 | 500ms defer 竞态 (#1.3) | 改成事件驱动：chat.on_ready 触发注册 |
| P2 | 同名 agent 覆盖 (#3.3) | add_agent 前检查，已存在则报错 |
| P2 | 日志 rotate (#5.3) | 启动时检查文件大小，超过 5MB 截断 |
