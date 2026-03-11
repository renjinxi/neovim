# ACP 频道系统 — 里程碑规划

## 愿景

你在 nvim 前，主 agent 是你的助手，子 agent 是它派出去干活的。频道是所有通信的可见层，人类随时介入。

## 架构

```
你（nvim 前）
  │
  └── 主 agent (AcpChat)
        │
        ▼
      频道 (bus)
        ├── 子 agent-1
        ├── 子 agent-2
        └── 子 agent-N
```

## 里程碑

### M0：单 Agent 私聊 + 频道 Buffer ✅

ACP 协议层跑通，能和一个 agent 对话。

- [x] jsonrpc.lua — JSON-RPC 2.0 编解码
- [x] adapter.lua — claude/gemini adapter 配置
- [x] client.lua — ACP 握手、prompt、流式接收、terminal/* 反向请求
- [x] chat.lua — 1v1 私聊 buffer UI
- [x] bus.lua — 频道 buffer（M0 简化版）
- [x] rpc.lua — nvim RPC 入口（bus_open/bus_post/bus_read/bus_send）
- [x] 协议层对齐 codecompanion 实现

### M1：频道协作（当前）

子 agent 静默干活，完成后主动发消息回频道，频道按 @mention 路由推送。

- [ ] bus.lua — `post()` 加路由：解析 @mention，调 `client:prompt()` 推送
- [ ] adapter.lua — 子 agent 启动时注入 system prompt（频道使用说明 + bash 命令模板）
- [ ] rpc.lua — 日志路径改到 `logs/acp-rpc.log`

详细设计见 [design/m1-redesign.md](design/m1-redesign.md)。

### M2：人机同频

你能在频道输入框参与对话，从旁观者变成参与者。

- [ ] 频道输入框可发消息，agent 能看到
- [ ] @ 路由对人类输入同样生效
- [ ] agent 回复能 @ 你

### M3：Agent 自主协作

Agent 之间能主动通信，不需要人类中转。子 agent 能 spawn 新 agent。

- [ ] 子 agent 能通过 bash 发消息给其他子 agent（@mention）
- [ ] 子 agent 能 spawn 新子 agent 加入频道
- [ ] 形成自主协作循环

### M4：频道树

频道可嵌套，agent 觉得任务太大就开子频道继续拆分。

### M5：远程 Agent

ACP 协议本身支持 HTTP/WebSocket，本地远程对 agent 透明。

## 关键文件

- `lua/acp/` — ACP 模块代码
- `notes/acp-channel/` — 项目文档
