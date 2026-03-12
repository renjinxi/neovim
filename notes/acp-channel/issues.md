# ACP 频道系统 — 问题清单

## P1 尾巴

### #1 推送稳定性
_push_to_main 并发问题，主 Claude 收到 @main 推送有时不回复。
状态：未复现，暂跳过

### #2 统一命名 ✅
子 agent system prompt 用 @主agent，路由只识别 @main。
修复：bus.lua 路由统一为 @main，system prompt 同步更新。

## 多 adapter 支持

### #3 Gemini 不回消息
args 顺序错误（--experimental-acp 在前），且握手时传了 terminal=true（gemini 不支持）。
修复：args 改为 ["--yolo", "--experimental-acp"]，adapter 加 terminal=false 字段，client 握手时按 adapter 决定 capabilities。
状态：待验证（需要 .env 里配置 GEMINI_API_KEY）

### #4 Codex adapter ✅
新增 codex adapter，cmd=codex-acp，auth=OPENAI_API_KEY。
状态：待验证（需要 .env 里配置 OPENAI_API_KEY）

## UX

### #5 频道不可随意关闭 ✅
修复：q 改为 hide()，只关窗口不杀进程。BufWipeout + VimLeavePre 自动清理进程。

### #6 Chat/频道双 buffer 体验差 ✅
修复：
- AcpToggle / <leader>ait：主+输入框成对 toggle
- AcpAgents / <leader>aia：统一 picker，列出所有 session，选中 toggle
- show() 修复 split 顺序，保证输入框成对出现

## Skill 问题

### #7 acp-bus-dispatch 轮询问题 ✅
修复：skill 隐藏 bus_agents/bus_read API，加推送机制说明，禁止 sleep 轮询。

## 多账号支持

### #8 多账号 ✅
修复：adapter.lua 新增 c1/c2，读取 CLAUDE_API1_*/CLAUDE_API2_* 环境变量。

## 新增问题

### #9 主 Claude chat 割裂
频道推送给主 Claude 的消息，在主 Claude 的 chat buffer 里看不到，很割裂。
修复：_push_to_main 在主 chat buffer 写入"← 频道"来源标记。
状态：待验证

### #10 频道消息无时间感知
不知道消息之间的时间间隔，慢/快无法感知。
修复：_render_message 加时间戳 + 与上条消息的间隔（+Xs）。
状态：待验证

### #11 通信延迟无法分析
不知道哪个环节慢。
修复：新增 logs/acp-client.log，记录握手耗时、prompt 耗时、terminal 操作耗时、stderr 输出。
状态：已上线
