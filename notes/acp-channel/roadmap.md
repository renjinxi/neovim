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

## 已完成的工作（截至 2026-03-12）

### 协议层
- jsonrpc.lua — JSON-RPC 2.0 编解码
- adapter.lua — claude/gemini adapter 配置
- client.lua — ACP 握手、prompt、流式接收、terminal/* 反向请求
- 协议层对齐 codecompanion 实现（normalize_params、sessionUpdate、get_renderable_text）

### 频道通信
- bus.lua — 频道 buffer + 输入框，人类直接参与对话
- @mention 路由：agent 之间、agent→main、人类→agent 都通
- 子 agent 通过 bash（terminal/create → nvim --server --remote-expr）发消息回频道
- bus_post_file 方案：消息写临时文件，避开 --remote-expr 引号嵌套问题
- 所有消息都过频道（包括 main 发给子 agent 的任务、main 的回复）
- 上线通知：main 和子 agent 注册时都显示

### 主 Claude 集成
- chat.lua — 1v1 私聊 buffer UI + on_ready 回调
- main_client 注册：open_chat/open_bus 互相注册
- _push_to_main：子 agent @main 时推送给主 Claude，回复 post 回频道

### 可观测性
- 每个子 agent 独立 chat_buf，记录完整对话（## You / ## Assistant / tool_call）
- :AcpAgents 命令：列出 agent 状态，选中跳转到 chat buffer
- 日志：acp-bus.log / acp-rpc.log

### 已知问题

#### P1 尾巴
1. **推送稳定性**：_push_to_main 并发问题，主 Claude 收到 @main 推送有时不回复（测试中）
2. **统一命名**：子 agent system prompt 用 @主agent，路由只识别 @main，需统一

#### 多 adapter 支持
3. **Gemini adapter 跑不通**：gemini CLI 启动后立即退出，可能是认证/ACP 握手问题。get_env 返回空，需排查
4. **Codex adapter 缺失**：adapter.lua 里没有 codex，需新增

#### UX
5. **频道不可随意关闭**：需要防止 agent 或误操作关掉频道 buffer
6. **Chat/频道双 buffer 打开体验差**：chat UI 和频道 UI 是两个 buffer，有时只能打开一个，切换不顺

## 里程碑

### P0：基础通信 ✅

协议层跑通，能和单个 agent 对话。

- [x] jsonrpc / adapter / client
- [x] chat.lua — 1v1 私聊 UI
- [x] rpc.lua — nvim RPC 入口

### P1：频道协作 🔧

多 agent 频道，@mention 路由，主/子双向推送，人类直接参与。

- [x] bus.lua — 频道 buffer + 输入框
- [x] @mention 路由（agent 间 + main + 人类）
- [x] 子 agent bash 通信（bus_post_file 方案）
- [x] 主 Claude 注册 + 双向推送
- [x] 所有消息过频道
- [ ] 推送稳定性：修复 _push_to_main 并发问题
- [ ] 统一命名：@main 替代 @主agent

### P2：可观测性 ✅

每个 agent 的对话可独立查看。

- [x] 子 agent 独立 chat_buf
- [x] :AcpAgents 命令
- [x] 日志系统

### P3：自主扩展

子 agent 能 spawn 新 agent，动态加入频道。

- [ ] 子 agent 通过 bash 调 rpc 创建新 agent
- [ ] rpc.lua 加 bus_add_agent RPC
- [ ] 动态加入频道后自动注入 system prompt

### P4：频道树

频道可嵌套，agent 觉得任务太大就开子频道继续拆分。

- [ ] Bus 支持 parent_bus 引用
- [ ] 子频道消息可选上报父频道
- [ ] 人类可以在频道间切换

### P5：远程 Agent

ACP 协议支持 HTTP/WebSocket，本地远程对 agent 透明。

- [ ] transport 层抽象（stdio / websocket）
- [ ] 远程 agent 注册和发现

## 关键文件

- `lua/acp/` — ACP 模块代码
- `notes/acp-channel/` — 项目文档
- `skills/acp-bus-dispatch/` — 频道调度 skill
