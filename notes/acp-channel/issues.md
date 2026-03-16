# ACP 频道系统 — 问题清单

最后更新：2026-03-16

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
| #13 | 频道持久化 | store.lua + bus.lua save_snapshot/restore + init.lua AcpBusSelect；已实现，待完整恢复流程验证 |
| #14 | c1/c2 代理环境变量丢失 | 新增 get_proxy_env()，所有 adapter 统一读 CLAUDE_PROXY |
| #15 | agent 不回消息时无反馈 | send_to_agent 增加 error 分支，频道 post "xxx 执行出错" |
| #16 | system prompt 精简 + 长内容写文件 | system prompt 精简；频道 50 字内，长内容写 notes/acp-bus/{channel_id}/ |
| #17 | agent 实时状态显示 | 频道 winbar 显示 offline/idle/busy + 当前 activity，事件驱动刷新 |
| #18 | 消息送达无反馈 | send_to_agent 发 prompt 时频道 post "→ xxx"，winbar 同步变绿 |
| #19 | 频道消息在主 chat buffer 里不易区分 | Chat.append_bus_message + `_push_to_main` 传发送者信息 |
| #34 | :Acp chat 应支持多实例 | open_chat 去掉同 adapter toggle，每次创建独立 chat 实例 |
| #36 | Chat 加入指定频道 | 已支持 `:Acp chat claude --join` 作为 main 加入当前活跃频道；子 agent join 待补充 |
| #37 | 启动 ACP Chat 期间键盘不响应 | open() 创建窗口后立即聚焦 input_win + startinsert，连接期可输入 |

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
- 注：待重新验证

---

## 待处理 ⏳

### #1 推送稳定性
`_push_to_main` 并发问题，多个 agent 同时 @main 可能乱序或丢失。
**状态**：未复现，暂跳过。

### #20 ACP 原生命令支持度 + Chat 输入框命令系统
两个相关需求：

**A. ACP 协议原生命令**
ACP 协议定义的会话管理命令（clear、compact/压缩上下文、退出等），当前支持到什么程度？需要排查：
- client.lua 是否实现了 clear / compact 等 session 管理命令
- 各 adapter（claude/gemini/codex）哪些原生命令可用
- ACP 协议规范里 session/* 还有哪些可用的 method

**B. Chat 输入框命令系统**
当前 Chat 和频道的 input 只能发消息，无法执行原生命令（如压缩上下文、清空会话、退出 agent 等）。
需要设计一套输入框命令机制，例如：
- `/compact` — 压缩当前会话上下文
- `/clear` — 清空会话
- `/exit` — 退出 agent
- `/status` — 查看连接状态
- 命令以 `/` 开头，和普通消息区分

**调研方向**：
1. 读 ACP 协议规范，列出所有可用的 session 管理 method
2. 读 codecompanion 参考实现（/tmp/codecompanion.nvim/），看他们怎么处理这类命令
3. 确认各 adapter CLI（claude --acp, gemini --acp, codex --acp）实际支持哪些命令
4. 设计 input 拦截层：`/xxx` 开头的走命令分发，其余走正常消息

**调研结果**：见 `research/adapter-native-commands.md`（codex1）+ 待合并 claude2 设计文档
**核心结论**：
- 统一可做：`session/load`（三家都支持）
- `compact` 按 adapter 分发：claude/codex → `/compact`，gemini → `/compress`
- `clear` / `resume` / `fork` 不统一，仅部分 adapter 支持
- CLI 命令 ≠ ACP 能力，不可混淆

**排期**：
1. 先实现 input 拦截层（`/` 开头走命令分发）— 可随 #39 一起做
2. 第一批命令：`/compact`（adapter-specific）、`/status`
3. `session/load` 接入 — 等 claude2 设计文档确认后排

**状态**：✅ 已实现（2026-03-16，claude3）。commands.lua + chat/channel_view 拦截。Chat: /status /cancel /exit /compact /leave。频道: /add /stop /list /open

### #21 轻量 task 层（codex1 建议）
频道从纯消息流升级为"消息 + 任务事件"。引入 task 对象（task_id, owner, status, artifacts），
UI 可显示"谁在做什么"而非"谁说了什么"。恢复时能恢复任务状态而非仅聊天历史。
**状态**：⚠️ 部分实现 — task.lua 数据模型已有（new/start/done/fail + artifacts），agent 有 current_task 字段，但 scheduler 尚未串入 task 流程

### #22 结构化协作原语（codex1 建议）
加 assign/done/blocked/artifact 四个动作的 RPC 原语，减少纯自然语言协议负担。
让 agent 通过接口上报状态而非靠 prompt 约定。
**状态**：❌ 未实现 — task.lua 有 done/artifact 方法但未暴露为 RPC

### #23 可观测性面板（codex1 建议）
`:Acp inspect` 展示 agent 状态、当前 task、运行时长、队列长度、最近错误、artifact 路径。
把真实状态从频道解耦，避免频道变日志垃圾桶。
**状态**：❌ 未实现 — 有 :Acp pick 和 /list 但不是完整观测面板

### #24 身份校验 + 背压机制（codex1 建议）
- from 字段无校验，可伪造。需 agent token/nonce 绑定
- 缺系统级背压：每 agent 最大排队数、全局最大并发数、超出回 busy
**状态**：⚠️ 部分实现 — scheduler 有 MAX_MAIN_QUEUE=10 + 丢弃通知（背压），main 串行队列防并发。身份校验未实现

### #25 模型能力差异化编排（codex1 建议）
给 adapter 标注 traits（strengths/cost_class/latency_class/tooling），
planner 按任务类型派单而非只按名字 @agent。
**状态**：❌ 未实现

### #26 多个 ACP Chat 实例导致 main 身份冲突
先起一个 ACP Chat，再开 bus，再起第二个 ACP Chat 时，会注册第二个 main agent。
导致频道里出现两个 main，路由和消息归属错乱。
**复现**：`:Acp chat claude` → `:Acp bus` + 加 agent → 再 `:Acp chat claude`
**预期**：bus 已有 main 时，新 ACP Chat 不应重复注册 main，或者应复用已有 main 的 chat 实例。
**状态**：✅ 已解决（重构后 on_ready 有 guard，main 已有活跃 client 时不覆盖，2026-03-16 claude3 排查）

### #27 主 agent 输出意外打到频道
主 agent（main）的正常对话输出有时会被路由到频道里显示，混入频道消息流。
疑似 on_update 回调在 bus 模式下把 main 的 streaming 内容也转发到了频道 buffer。
需排查 chat.lua 的 `_on_update` 在 bus 模式下对 main agent 的处理逻辑。
**状态**：✅ 已解决（main Chat 的 on_agent_update 未设置，streaming 不泄漏，2026-03-16 claude3 排查）

### #28 多频道支持
当前只能同时存在一个频道实例（Bus singleton）。需支持多个独立频道并行运行，各自有独立的 agent 集合和消息流。
频道间暂不考虑关联/嵌套（那是 P4 频道树的范畴），先解决多个独立频道共存的问题。
**状态**：✅ 已实现 — registry.lua channels map 支持多频道并存 + active_channel_id 切换

### #29 架构重新设计
经过 M0 实现和 codex1 的架构审查（#21-#25），当前架构存在多处需要重构的地方：
- 任务层缺失（#21）、结构化协作原语（#22）、可观测性（#23）、背压（#24）、模型编排（#25）
- Chat/Bus/Client 职责边界需要重新梳理（#26 #27 暴露的耦合问题）
- 需要一次整体架构 review + 重新设计，而非逐个打补丁
**状态**：✅ 已完成 — 三阶段全部落地：agent/router/scheduler/task 独立模块 + channel/channel_view 拆分 + registry 全局注册表 + bus facade

### #30 session/new 超时 + 自动重试
启动 claude agent 时经常 session/new 超时（当前 15s）。两个需求：
1. 超时时间可配置（或适当延长默认值）
2. 超时/失败后自动重试（至少重试 1-2 次），而非直接报错让用户手动重来
**状态**：✅ 已验证（30s + 2次重试 + 2s间隔，2026-03-16 claude3 确认代码已实现）

### #31 子 agent 不回复频道（不会用工具回复）
子 agent 处理完消息后经常不回复频道。原因：agent 需要通过 bash 工具调 nvim RPC 才能 post 到频道，但 system prompt 里的回复指令不够明确，agent 容易"忘记"或不知道怎么用工具回复。
已观察到 codex、claude1 都出现过此问题。
**可能方案**：
- system prompt 里给出完整的回复命令模板，降低 agent 的认知负担
- 或者改架构：agent prompt 完成后，bus 自动把 stream_buf 内容 post 到频道（不依赖 agent 主动回复）
**状态**：✅ 已通过 #32 解决 — idle 通知 "@main 已 idle（未主动回复）"，main 自行决定后续

### #32 agent idle 时频道系统通知
agent 从 streaming→idle 时，频道自动 post 一条系统消息"xxx 已完成"（no_route，不触发路由）。
改动点：`send_to_agent` prompt 回调里正常完成时加一行 post。
不需要 push 到 main agent（避免浪费 token），频道消息即可。
**状态**：✅ 已实现（2026-03-16，codex1）

### #33 agent 回复自动收集到频道（待讨论）
agent prompt 完成后，bus 自动把 stream_buf 内容 post 到频道，替代 agent 手动用工具回复。
**问题**：agent 输出可能很长，直接灌到频道会很乱，不够灵活。
**可能方案**：长内容截断/摘要、写文件后只 post 路径、由 agent 自行决定回复什么
**状态**：✅ 不需要 — #32 idle 通知已解决核心问题，main agent 自行决定是否需要 agent 的输出

### #34 :Acp chat 应支持多实例
### #36 Chat 加入指定频道
独立 Chat 需要能选择加入频道，且不限于 main 角色。
**待补充**：
- `:Acp chat claude --join <agent_name>` — 作为普通子 agent 加入频道（不是 main）
- 例如 `:Acp chat claude --join reviewer` 就注册为频道里的 reviewer agent
- 这样用户可以用独立 Chat 窗口和频道里的任意角色交互，不局限于 main
- 实现：on_ready 时调 channel:add_agent 或直接注册到 agents[agent_name]
**状态**：✅ 已完成（2026-03-16，claude3 补充子 agent join）

### #38 agent 回调通道状态不可见 + 断连问题
当前有两条通道：
- **ACP 协议通道**（nvim → agent）：通过 client.lua 管理，winbar 有状态显示
- **RPC 回调通道**（agent → nvim）：agent 通过 bash 调 nvim socket 回复频道，**状态完全不可见**
问题：ACP 通道活着但 RPC 回调断了时，winbar 显示正常 idle，用户无法发现 agent 回不了消息。
**需要**：
1. winbar 或 inspect 面板显示双通道状态（ACP ✓/✗ + RPC 回调 ✓/✗）
2. 检测回调通道健康：agent 发 bus_post 失败时系统能感知
3. socket 稳定性：固定 symlink 或其他方案确保 agent 总能找到当前 nvim
**状态**：✅ 已实现（2026-03-16，claude3）。agent 加 last_rpc_time/prompt_start_time，winbar 在 streaming>60s 且无 RPC 时显示 "RPC?" 警告

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
**状态**：✅ 已实现（2026-03-16，codex1 + claude3 修复 UTF-8/路径）

### #39 Telescope agent picker + 快速进入 agent CLI
当前 `:Acp cli <name>` 需要手打 agent 名字。需要一个 Telescope picker：
- 列出当前频道所有 agent（名称、adapter、状态、session_id）
- 选中后直接打开该 agent 的原生 CLI（`claude --resume <session_id>`）
- 也可以选中后 show 该 agent 的 Chat 窗口
- 复用 `:Acp list` 的数据源，但用 Telescope 替代 vim.ui.select
**状态**：✅ 已实现（2026-03-16，codex2）。picker.lua + :Acp pick + /pick 频道命令

### #40 频道 UI markdown 渲染优化
频道 buffer 的消息对人类不够友好，需要改善可读性：
- filetype 已是 markdown，但消息格式是纯文本拼接，没用 markdown 语法
- 可以用 `## sender` 做消息头、代码块包裹代码、分割线分隔消息等
- 参考 chat.lua 的渲染方式，让频道消息也适合人类阅读
**状态**：✅ 已实现（2026-03-16，codex1 + claude3 review）

### #43 chat.lua `_append_system` 换行崩溃
`_append_system` 直接把 text 塞进单行 `nvim_buf_set_lines`，text 含换行时报错：
`'replacement string' item contains newlines`
**根因**：和 #12 同类，需要 `vim.split(text, "\n")` 后再传。
**位置**：`lua/acp/chat.lua:427`
**状态**：✅ 已修复（2026-03-16，codex1）

### #42 agent 主动退出频道
用户或 agent 需要能主动退出频道（而非只能 stop/kill）：
- 频道 UI 或命令支持 `:Acp leave <agent_name>` 或 `/leave`
- agent 退出后从 agents 列表移除、winbar 更新、频道 post 系统通知
- 与 #41 异常退出区分：这是正常的主动退出流程
**状态**：✅ 已实现（2026-03-16，codex1 + claude3 review）

### #41 agent 进程异常退出未清理
agent 在频道里死了（进程崩溃/被 kill）但没有正确退出频道：
- winbar 可能还显示 idle/online 状态
- 需要检测 agent 进程退出并自动更新状态 + 通知频道
- 检查 chat.on_exit_notify 是否在所有退出场景都能触发
**状态**：✅ 已验证，不是 bug（退出回调链完整，2026-03-16 claude3 排查）

---

## 功能路线图

### P3：子 agent 自主扩展（未开始）
子 agent 能通过 bash 调 RPC 创建新 agent，动态加入频道。
- [ ] rpc.lua 加 bus_add_agent 接口
- [ ] 子 agent system prompt 加 spawn 指令
- [ ] 动态加入后自动注入 system prompt

### P4：频道树（未开始）
频道可以嵌套，子频道独立运行后汇报给父频道。

### P5：AI Coordinator（远期构想）
当 agent 数量和频道复杂度超过人能手动管理的范围时（10+ agent、嵌套频道、跨频道依赖），
引入 AI coordinator 角色：判断任务是否真正完成、是否需要 escalate 给人类、自动调度跨频道依赖。
前提：task 层 + 协作原语 + 嵌套频道都要先稳定。
现阶段用确定性规则追踪就够了。
