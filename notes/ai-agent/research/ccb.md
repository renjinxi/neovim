# Claude Code Bridge (CCB) 研究

来源: https://github.com/bfly123/claude_code_bridge
技术栈: Python (~28K 行)
版本: v5.2.6
支持: Claude / Codex / Gemini / OpenCode / Droid 五个 AI CLI

## 项目定位

**终端级别的多 AI 实时协作框架。** 核心理念："交互皆可见，模型皆可控"。

和 myclaude 的本质区别：myclaude 是"指挥官调度执行者"，CCB 是"多个 AI 在分屏终端里互相对话"。

## 核心架构

```
┌──────────────────────────────────────────────────────┐
│  tmux / wezterm 分屏终端                               │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │ Claude   │  │ Codex    │  │ Gemini   │  ← 人可以  │
│  │ (pane 1) │  │ (pane 2) │  │ (pane 3) │    切到任  │
│  │          │  │          │  │          │    意 pane  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘   直接打字 │
│       │              │              │                 │
│       └──────┬───────┴──────┬───────┘                 │
│              ↓              ↓                         │
│  ┌───────────────────────────────────────┐            │
│  │  askd（统一守护进程，TCP JSON-RPC）     │            │
│  │                                       │            │
│  │  ProviderRegistry                     │            │
│  │  ├─ ClaudeAdapter   → pane 注入 + 日志轮询         │
│  │  ├─ CodexAdapter    → FIFO + 日志监听              │
│  │  ├─ GeminiAdapter   → pane 注入 + JSON 解析        │
│  │  ├─ OpenCodeAdapter → SQLite + pane 注入           │
│  │  └─ DroidAdapter    → pane 注入 + 日志监听          │
│  │                                       │            │
│  │  WorkerPool（每 session 独立 worker）   │            │
│  └───────────────────────────────────────┘            │
└──────────────────────────────────────────────────────┘
```

## 通信机制

### 1. 文本标记协议

不用复杂的序列化，用简单的文本标记：

```
CCB_REQ_ID: 20260307-143000-123-12345-0    # 请求 ID
CCB_BEGIN: 20260307-143000-123-12345-0     # 回复开始
CCB_DONE: 20260307-143000-123-12345-0      # 回复完成
```

AI 收到带 CCB_REQ_ID 的消息 → 处理 → 输出 CCB_BEGIN → 内容 → CCB_DONE。
调用方通过监听日志文件/session 文件，看到 CCB_DONE 就知道完成了。

### 2. 异步委托 + 完成回调

```
Claude: ask codex "重构这个函数"
  → askd 守护进程收到
  → 往 Codex 的 pane 注入文字
  → Claude 不等待，继续干别的
  → Codex 跑完，输出 CCB_DONE
  → 完成回调注入 Claude 的 pane：[CCB_TASK_COMPLETED]
  → Claude 收到通知，用 pend 读结果
```

### 3. 三个核心命令

| 命令 | 作用 |
|------|------|
| `ask <provider> <message>` | 给某个 AI 发消息（异步） |
| `pend <provider> [N]` | 读某个 AI 的最新回复 |
| `ccb-ping <provider>` | 检查某个 AI 是否在线 |

### 4. 回复获取方式（按 provider 不同）

| Provider | 怎么拿到回复 |
|----------|-------------|
| Claude | 读 `~/.claude/projects/<key>/<session>.jsonl` |
| Codex | FIFO + 读 `~/.codex/sessions/<uuid>/` 日志 |
| Gemini | 读 `~/.gemini/tmp/<hash>/chats/session-*.json` |
| OpenCode | 读 SQLite `~/.local/share/opencode/storage` |
| Droid | 读 `~/.factory/sessions/<slug>/<session>.jsonl` |

关键：每个 AI CLI 的 session 文件格式不同，CCB 为每个都写了专门的 adapter。

## askd 守护进程

单进程管理所有 provider，TCP JSON-RPC 通信：

- Token 认证
- 空闲 60 秒自动退出
- 父进程死了自动退出
- 每 2 秒心跳
- 每个 session 独立 worker 线程，防止上下文污染

## MCP 集成

CCB 把 ask/ping/pend 暴露为 MCP tools：

```python
# mcp/ccb-delegation/server.py
TOOL_DEFS = [
    "ccb_ask_codex", "ccb_ask_gemini", "ccb_ask_claude", "ccb_ask_opencode",
    "ccb_pend_codex", "ccb_pend_gemini", "ccb_pend_claude", "ccb_pend_opencode",
    "ccb_ping_codex", "ccb_ping_gemini", "ccb_ping_claude", "ccb_ping_opencode",
]
```

这样不支持 Bash 调用的 AI（如 Droid/Factory）也能通过 MCP tool 调用 CCB。

## 项目隔离

```
<project>/
├── .ccb/                    # 项目锚点
│   ├── ccb.config           # provider 列表
│   ├── .claude-session      # Claude session 绑定
│   ├── .codex-session       # Codex session 绑定
│   ├── .gemini-session      # Gemini session 绑定
│   └── history/             # 自动导出的上下文
```

每个项目独立的 session 绑定，不会跨项目污染。

## 跨平台

| 平台 | 终端后端 |
|------|---------|
| Linux/macOS | tmux 分屏 |
| Windows | WezTerm 分屏 |
| WSL | 自动路径转换 |

## 对我们 AI-to-AI 目标的满足度

| 目标 | 满足度 | 说明 |
|------|--------|------|
| AI 调 AI | ✅ | ask 命令，任意 AI 给任意 AI 发消息 |
| 结构化通信 | ✅ | CCB 协议标记 + JSON-RPC |
| 多 CLI 支持 | ✅ | 5 个后端（Claude/Codex/Gemini/OpenCode/Droid） |
| 人可介入 | ✅ | 每个 AI 在 tmux pane 里，人切过去直接打字 |
| 人可观察 | ✅ | 分屏终端，所有交互可见 |
| 完成检测 | ✅ | CCB_DONE 标记 + 完成回调 |
| 实时通信 | ⚠️ | 异步回调，不是 mid-turn 注入（比 hcom 慢） |
| 项目隔离 | ✅ | .ccb/ 锚点 + session 绑定 |

## 和 hcom 的对比

| | CCB | hcom |
|---|---|---|
| 语言 | Python | Rust |
| 终端管理 | tmux/wezterm 分屏 | PTY 包裹 |
| 消息注入 | tmux send-keys | PTY stdin 注入 |
| 完成检测 | 文本标记 CCB_DONE | vt100 解析状态 |
| 回复获取 | 读 session 文件 | PTY 屏幕读取 |
| 实时性 | 异步回调（秒级） | mid-turn 注入（毫秒级） |
| 状态检测 | 无（靠标记） | 完整状态机（空闲/忙/审批） |
| 碰撞检测 | 无 | 自动检测同文件编辑 |
| 守护进程 | askd（Python TCP） | hcom（Rust TCP + SQLite） |
| 复杂度 | 中等 | 高 |
| 稳定性 | 较好（不依赖 vt100） | 脆弱（依赖终端转义序列） |
| MCP | ✅ 暴露为 MCP tools | ❌ |

## 关键洞察

### CCB 比 hcom 更务实

hcom 在 PTY 层面做了很多精巧的事（vt100 解析、状态检测、mid-turn 注入），但也因此更脆弱。

CCB 的思路更简单直接：
1. 每个 AI 在 tmux pane 里正常跑
2. 通过 tmux send-keys 注入消息
3. 通过读 session 文件拿回复
4. 用文本标记做完成检测

不需要 PTY 包裹，不需要 vt100 解析，不需要状态机。代价是实时性差一些（秒级 vs 毫秒级），但对大多数场景够用。

### 读 session 文件是个聪明的做法

CCB 不读 terminal 输出（有 ANSI 颜色码的问题），而是直接读各 AI CLI 的 session 文件：
- Claude 的 .jsonl
- Codex 的 .jsonl
- Gemini 的 .json
- OpenCode 的 SQLite

这些文件是结构化的，没有 ANSI 噪音，解析可靠。

### 和 nvim 的关系

CCB 用 tmux 做终端管理。我们用 nvim terminal。
本质一样：都是在终端分屏里跑多个 AI，通过注入文字通信。

区别：
- CCB 依赖 tmux/wezterm
- 我们依赖 nvim terminal buffer
- CCB 的 askd 守护进程可以独立于终端管理器

## 结论

**思路有参考价值，但依赖 tmux 是硬伤。**

输出侧的设计不错：读 session 文件 + 文本标记协议 + watchdog 文件监听，比读 terminal 屏幕可靠。askd 守护进程里没有 AI，纯程序逻辑（文件监听 + 正则匹配 CCB_DONE）。

但问题也明显：
- 输入侧绑死 tmux send-keys，不如 hcom 的 PTY 层通用
- 5 个后端各写一套 session 文件解析器，维护成本高
- 不如自定义统一文件格式来得干净

可借鉴的点：
1. 读 session 文件而不是 terminal 输出（解决 ANSI 问题）
2. 文本标记做完成检测（CCB_DONE）
3. 异步委托 + 完成回调不阻塞调用方
4. 后台守护进程统一管理通信
