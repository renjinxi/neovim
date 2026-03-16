# ACP 频道系统 — 问题清单

最后更新：2026-03-15

---

## 已解决 ✅

| # | 问题 | 修复内容 |
|---|------|---------|
| #2 | 统一命名 @主agent→@main | bus.lua 路由 + system prompt 统一 |
| #4 | Codex adapter 缺失 | 已加，但当前版本不支持 ACP，已注释禁用 |
| #4 | Codex adapter 缺失 | 已加 codex-acp adapter，codex 可通过频道通信 |
| #5 | 频道 buffer 被误关 | q 改为 hide()，BufWipeout+VimLeavePre 自动清理进程 |
| #6 | Chat/频道双 buffer 体验差 | AcpToggle(<leader>ait)、AcpAgents picker(<leader>aia)、show() 修复 split 顺序 |
| #7 | skill 轮询问题 | 隐藏 bus_agents/bus_read，加推送机制说明 |
| #8 | 多账号支持 | c1/c2 adapter，读 CLAUDE_API1_*/CLAUDE_API2_* |
| #9 | 主 Claude chat 割裂 | _push_to_main 在主 chat buffer 写"← 频道"标记 |
| #10 | 频道消息无时间感知 | _render_message 加时间戳 + 间隔（+Xs） |
| #11 | 通信延迟无法分析 | 新增 logs/acp-client.log，记录握手/prompt/terminal 耗时 |
| #12 | _append_agent_system 换行崩溃 | vim.split 后再传 nvim_buf_set_lines |
| #14 | c1/c2 代理环境变量丢失 | 新增 get_proxy_env()，所有 adapter 统一读 CLAUDE_PROXY |

---

## 进行中 🔧

### #3 Gemini 不回消息
**根本原因**：ACP 握手缺少 authenticate 步骤。gemini 握手流程是：
`initialize → authenticate → session/new`，我们之前跳过了 authenticate。

**已修**：
- client.lua 补全 authenticate 步骤
- adapter: args 改为 `--acp`（`--experimental-acp` 已 deprecated）
- adapter: auth_method 改为 `LOGIN_WITH_GOOGLE`（用本地 OAuth 凭证，不需要 API key）

**进展**：
- authenticate 失败原因找到：methodId 传的是枚举名 `LOGIN_WITH_GOOGLE`，实际值应该是 `oauth-personal`
- 已修改 adapter.lua，改为 `auth_method = "oauth-personal"`
- 待验证：重启 nvim 后测试 `:AcpChat gemini`

---

## 待处理 ⏳

### #1 推送稳定性
`_push_to_main` 并发问题，多个 agent 同时 @main 可能乱序或丢失。
**状态**：未复现，暂跳过。

### #13 频道持久化
频道关闭/nvim退出时自动保存快照，`:AcpBusSelect` 恢复。
**已实现**：store.lua + bus.lua save_snapshot/restore + init.lua AcpBusSelect（2026-03-15）
**M0 限制**：恢复时 agent 走 session/new，不依赖 session/load
**待验证**：重启后测试完整恢复流程

### #15 agent 不回消息时无反馈
`send_to_agent` 的 prompt 回调只处理 `cancelled`，`error` 时完全静默。
**已修**：加 `stop=error` 处理，post "xxx 执行出错" 到频道（2026-03-15）

### #16 system prompt 精简 + 长内容写文件
频道消息太长太乱，agent 大段分析直接刷屏。
**已修**（2026-03-15）：
- system prompt 精简到最小：只管通信命令 + 基本规则
- 频道消息 50 字以内，长内容写 `notes/acp-bus/{channel_id}/`
- 角色定义由 main agent 启动时的消息决定，不硬编码

### #17 agent 实时状态显示
不知道 agent 在不在干活。
**已实现**（2026-03-15）：
- 频道主窗口 winbar 显示各 agent 状态：○ offline / ◉ idle / ● busy
- busy 时显示当前活动：[thinking] / [Read File] / [typing]
- 事件驱动刷新，不轮询

### #18 消息送达无反馈
发消息给 agent 后不知道是否送达。
**已修**（2026-03-15）：
- `send_to_agent` 发 prompt 时 post "→ xxx" 到频道
- winbar 同步变绿

### #19 频道消息在主 chat buffer 里不易区分
频道推给 main 的消息和手动对话混在一起。
**已修**（2026-03-15）：
- Chat 加 `append_bus_message(from, text)` 方法
- 频道来源消息显示为 `## 📨 频道 ← {agent名}`，区别于普通 `## You`
- `_push_to_main` 传递发送者信息

### #20 ACP 原生命令支持度
ACP 协议定义的原生命令（clear、compact/压缩上下文、等），当前支持到什么程度？需要排查：
- client.lua 是否实现了 clear / compact 等 session 管理命令
- 各 adapter（claude/gemini/codex）哪些原生命令可用
- 是否需要在 UI 层暴露这些操作（比如 `:Acp clear agent_name`）

**状态**：待调研

### #21 轻量 task 层（codex1 建议）
频道从纯消息流升级为"消息 + 任务事件"。引入 task 对象（task_id, owner, status, artifacts），
UI 可显示"谁在做什么"而非"谁说了什么"。恢复时能恢复任务状态而非仅聊天历史。
**状态**：待设计

### #22 结构化协作原语（codex1 建议）
加 assign/done/blocked/artifact 四个动作的 RPC 原语，减少纯自然语言协议负担。
让 agent 通过接口上报状态而非靠 prompt 约定。
**状态**：待设计

### #23 可观测性面板（codex1 建议）
`:Acp inspect` 展示 agent 状态、当前 task、运行时长、队列长度、最近错误、artifact 路径。
把真实状态从频道解耦，避免频道变日志垃圾桶。
**状态**：待设计

### #24 身份校验 + 背压机制（codex1 建议）
- from 字段无校验，可伪造。需 agent token/nonce 绑定
- 缺系统级背压：每 agent 最大排队数、全局最大并发数、超出回 busy
**状态**：待设计

### #25 模型能力差异化编排（codex1 建议）
给 adapter 标注 traits（strengths/cost_class/latency_class/tooling），
planner 按任务类型派单而非只按名字 @agent。
**状态**：待设计

### #26 多个 ACP Chat 实例导致 main 身份冲突
先起一个 ACP Chat，再开 bus，再起第二个 ACP Chat 时，会注册第二个 main agent。
导致频道里出现两个 main，路由和消息归属错乱。
**复现**：`:Acp chat claude` → `:Acp bus` + 加 agent → 再 `:Acp chat claude`
**预期**：bus 已有 main 时，新 ACP Chat 不应重复注册 main，或者应复用已有 main 的 chat 实例。
**状态**：待修复

### #27 主 agent 输出意外打到频道
主 agent（main）的正常对话输出有时会被路由到频道里显示，混入频道消息流。
疑似 on_update 回调在 bus 模式下把 main 的 streaming 内容也转发到了频道 buffer。
需排查 chat.lua 的 `_on_update` 在 bus 模式下对 main agent 的处理逻辑。
**状态**：待排查

### #28 多频道支持
当前只能同时存在一个频道实例（Bus singleton）。需支持多个独立频道并行运行，各自有独立的 agent 集合和消息流。
频道间暂不考虑关联/嵌套（那是 P4 频道树的范畴），先解决多个独立频道共存的问题。
**状态**：待设计

### #29 架构重新设计
经过 M0 实现和 codex1 的架构审查（#21-#25），当前架构存在多处需要重构的地方：
- 任务层缺失（#21）、结构化协作原语（#22）、可观测性（#23）、背压（#24）、模型编排（#25）
- Chat/Bus/Client 职责边界需要重新梳理（#26 #27 暴露的耦合问题）
- 需要一次整体架构 review + 重新设计，而非逐个打补丁
**状态**：待设计，进入 M1 前需完成

### #30 session/new 超时 + 自动重试
启动 claude agent 时经常 session/new 超时（当前 15s）。两个需求：
1. 超时时间可配置（或适当延长默认值）
2. 超时/失败后自动重试（至少重试 1-2 次），而非直接报错让用户手动重来
**状态**：claude2 已修（30s + 重试2次）

### #31 子 agent 不回复频道（不会用工具回复）
子 agent 处理完消息后经常不回复频道。原因：agent 需要通过 bash 工具调 nvim RPC 才能 post 到频道，但 system prompt 里的回复指令不够明确，agent 容易"忘记"或不知道怎么用工具回复。
已观察到 codex、claude1 都出现过此问题。
**可能方案**：
- system prompt 里给出完整的回复命令模板，降低 agent 的认知负担
- 或者改架构：agent prompt 完成后，bus 自动把 stream_buf 内容 post 到频道（不依赖 agent 主动回复）
**状态**：待设计

### #32 agent idle 时频道系统通知
agent 从 streaming→idle 时，频道自动 post 一条系统消息"xxx 已完成"（no_route，不触发路由）。
改动点：`send_to_agent` prompt 回调里正常完成时加一行 post。
不需要 push 到 main agent（避免浪费 token），频道消息即可。
**状态**：待实现

### #33 agent 回复自动收集到频道（待讨论）
agent prompt 完成后，bus 自动把 stream_buf 内容 post 到频道，替代 agent 手动用工具回复。
**问题**：agent 输出可能很长，直接灌到频道会很乱，不够灵活。
**可能方案**：长内容截断/摘要、写文件后只 post 路径、由 agent 自行决定回复什么
**状态**：待讨论，暂不实现

### #34 :Acp chat 应支持多实例
当前 `open_chat()` 对同 adapter 做 toggle（同类型只允许一个），`:Acp chat claude` 第二次只会 show/hide 已有的 chat。
**预期**：每次 `:Acp chat claude` 都创建新的独立 chat 实例，各自有独立的 session。
**改动点**：init.lua `open_chat()` 去掉同类型 toggle 逻辑，或加子命令区分（`:Acp chat claude new` vs `:Acp chat claude`）
**状态**：待修复

### #35 频道长消息自动文件化
agent 经常无视 system prompt 的"长内容写文件"规则，直接大段文字刷屏频道。
**方案**：两层——引导优先，兜底保底。
**第一层：引导 agent 主动写文件**
- RPC 加"附件"语义：bus_post 支持 `{text, attachment: "path/to/file.md"}`，agent 只需传路径
- 频道显示摘要 + 文件链接，agent 自己决定摘要内容，比系统截断更合理
- system prompt 给出附件用法模板，降低认知负担
**第二层：系统兜底强制截断**
- channel:post() 检测消息长度，超过阈值（300 字）时自动写文件 + 频道只显示摘要
- 对 agent 透明，不需要改 prompt
**排期**：阶段二完成后实现（依赖 channel.lua 抽出）
**状态**：待实现

---

## 功能路线图

### P3：子 agent 自主扩展（未开始）
子 agent 能通过 bash 调 RPC 创建新 agent，动态加入频道。
- [ ] rpc.lua 加 bus_add_agent 接口
- [ ] 子 agent system prompt 加 spawn 指令
- [ ] 动态加入后自动注入 system prompt

### P4：频道树（未开始）
频道可以嵌套，子频道独立运行后汇报给父频道。
