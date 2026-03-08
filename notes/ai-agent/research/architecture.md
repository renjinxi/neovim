# AI-to-AI 通信架构（现状）

## 核心链路

```
┌─────────────┐     agent_api      ┌─────────────┐
│  Claude-1   │ ──────────────────→ │    nvim      │
│ (当前终端)   │ ←────────────────── │  (中枢)      │
└─────────────┘                     └──────┬──────┘
      ↑                                    │
      │ 你直接打字交互                       │ terminal buffer
      │                                    ↓
┌─────────────┐                     ┌─────────────┐
│    你        │ ── 切 tab 直接打字 → │  Claude-2   │
│   (人)       │                     │ (子终端)     │
└─────────────┘                     └─────────────┘
```

## 通信方式

| 方向 | 方法 | 本质 |
|------|------|------|
| Claude-1 → Claude-2 | `send_to_terminal` | 往 Claude-2 的 stdin 打字 |
| Claude-2 → Claude-1 | `get_terminal_output` | Claude-1 主动读 Claude-2 的 terminal buffer |
| 人 → Claude-1 | 直接在 Claude-1 的终端打字 | 正常 CLI 交互 |
| 人 → Claude-2 | 切到 Claude-2 的 tab 打字 | 正常 CLI 交互 |
| 人 → 观察全局 | `:ls` 看 buffer 列表 / 切 tab | nvim 原生能力 |

## 关键事实

1. **Claude CLI 是黑盒** — 它只认自己 terminal 的 stdin/stdout，不会主动读 nvim buffer
2. **通信是单向控制** — Claude-1 控制 Claude-2，Claude-2 不知道 Claude-1 的存在
3. **terminal buffer 就是通信介质** — 不需要额外的信箱/总线 buffer
4. **人介入 = 切 tab 打字** — 和平时用 `:AI` 一模一样

## 典型流程

```
1. 你 → Claude-1: "开个 Claude-2 去 review init.lua"
2. Claude-1: spawn_cli({cmd="claude --dangerously-skip-permissions"})
3. Claude-1: send_to_terminal({name="review", text="review lua/core/init.lua\n"})
4. Claude-2 在另一个 tab 里跑...
5. 你看到跑完了，或者 Claude-1 轮询判断
6. 你 → Claude-1: "去读一下结果"
7. Claude-1: get_terminal_output({name="review", tail=100})
8. Claude-1 拿到结果，继续干活
```

## 权限处理

| 模式 | 启动参数 | 适用场景 |
|------|---------|---------|
| 全自动 | `claude --dangerously-skip-permissions` | 信任的低风险任务 |
| 半自动 | `claude --permission-mode acceptEdits` | 允许编辑，其他要确认 |
| 人工确认 | `claude`（默认） | 你切过去自己按 y/n |

gemini: `-y` (全自动) / codex: `-a full-auto`

## 现有 API

```lua
-- agent_api.lua 已实现的函数
spawn_cli({cmd, mode?, name?})           -- 开终端
send_to_terminal({name?, bufnr?, text})  -- 发文字
get_terminal_output({name?, bufnr?, tail?}) -- 读输出
list_terminals()                         -- 列出所有终端
```

## 待解决

- [ ] Claude-1 怎么判断 Claude-2 "跑完了"（目前只能轮询或人工告知）
- [ ] terminal 输出有 ANSI 颜色码，机器解析不干净
- [ ] 多个子 AI 的管理和状态追踪

## 思路：自定义文件协议通信

不读各 AI 的 session 文件（格式各异，要写 N 套解析器），而是定义统一的文件格式：

```
~/.ai-comm/
├── task-001.md           # 任务描述
├── task-001.result.md    # 执行结果（AI 写的）
└── task-001.status       # running / done / error
```

所有 AI 都读同一个格式、写同一个格式。不依赖任何 AI 的内部文件格式。

通知方式还是"往终端打字"（send_to_terminal / tmux send-keys / PTY 注入），
但回复内容通过文件传递，不读 terminal 也不读 session 文件。

好处：不绑定任何 AI 内部实现，加新 AI 零成本。
问题：要让每个 AI 都"知道"这套规则——只能通过 prompt 约定或 MCP tool。
状态：待细化，先记录。

## 相关文档

- [目标定义](ai-to-ai-goal.md) — 我们要达成什么
- [方案对比](ai-to-ai-solutions.md) — Terminal / ACP / SDK-URL / 混合四种方案的权衡
- [研究报告](ai-to-ai-research.md) — codecompanion / avante / copilot 三个插件的源码研究
- [SDK-URL 研究](ai-to-ai-sdk-url.md) — mc / team-anya 项目的 SDK-URL 实现细节
- [Codex App Server](ai-to-ai-codex-appserver.md) — OpenAI 的 agent runtime 架构（thread/turn/item 模型）
- [落地方案](ai-to-ai-landing-plan.md) — agent_api + mcp_agent_mail 方案
- [场景和模式](ai-to-ai-scenarios.md) — MCP 邮件 / 模拟人类输入 / 主循环编排三种模式

- [Ruflo 研究](ai-to-ai-ruflo.md) — 消息总线/共享记忆/模型路由等概念（深度绑定 Claude Code，不通用）
- [hcom 研究](ai-to-ai-hcom.md) — PTY 级别的跨 CLI agent 通信（目前最理想方案）

- [/loop + MCP 方案](ai-to-ai-loop-mcp.md) — Claude Code 定时轮询 + MCP 通信（简单但仅限 Claude Code）
- [Codex 源码研究](ai-to-ai-codex-source.md) — OpenAI Codex CLI 架构（Rust、多 agent、app-server、MCP server）
- [myclaude 研究](ai-to-ai-myclaude.md) — 多 Agent 编排平台（codeagent-wrapper 多后端抽象、Context Pack 通信、并行任务）
- [CCB 研究](ai-to-ai-ccb.md) — 终端级多 AI 协作框架（tmux 分屏、askd 守护进程、session 文件读取、文本标记协议）
- [CAO 研究](ai-to-ai-cao.md) — CLI Agent Orchestrator（tmux + FastAPI + SQLite inbox + MCP + watchdog）

## 探索进度

- [x] 研究 codecompanion / avante / copilot 的通信方式
- [x] 理解 ACP 协议
- [x] 整理四种方案的对比
- [x] 查看 mc 项目的 sdk-url 实现
- [x] 查看 team-anya 项目的 sdk-url 实现
- [x] 研究 Codex App Server 架构（thread/turn/item 模型）
- [x] 研究 Claude Code agent teams 机制
- [x] 研究 mcp_agent_mail 项目
- [x] 确定落地方案：agent_api + mcp_agent_mail
- [x] 整理三种协作场景（MCP邮件 / 模拟人输入 / 主循环编排）
- [x] 研究 Ruflo (claude-flow) 编排平台
- [x] 研究 A2A 协议（面向后端服务，CLI 不支持）
- [x] 研究 hcom — PTY 注入方案（目前最理想）
- [x] 研究 /loop + MCP 方案（简单但仅 Claude Code）
- [x] 研究 Codex 源码（Rust 架构、进程内多 agent、app-server、MCP server）
- [x] 研究 myclaude（多后端抽象、Context Pack、并行任务、Hook 防退出）
- [x] 研究 CCB（tmux 分屏协作、askd 守护进程、session 文件读取、MCP 暴露）
- [x] 研究 CAO（tmux + FastAPI + SQLite inbox + MCP + watchdog，工程化最高）
- [ ] 深入理解 PTY/TTY 机制
- [ ] 验证 hcom 实际使用效果
