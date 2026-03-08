# CLI Agent Orchestrator (CAO) 研究

来源: https://github.com/awslabs/cli-agent-orchestrator
技术栈: Python, tmux, SQLite, FastAPI, FastMCP, watchdog
规模: ~40 个 Python 源文件，结构清晰

## 它是什么

tmux 上的多 AI CLI 编排系统。用 tmux session/window 隔离每个 agent，通过 HTTP API + MCP Server 协调通信。

## 架构

```
CLI (cao launch) / MCP Server (handoff, assign, send_message)
        ↓
   FastAPI HTTP API (:9889)
        ↓
   Services 层 (session / terminal / inbox / flow)
        ↓
   Clients 层 (tmux + SQLite)
        ↓
   Providers 层 (kiro_cli / claude_code / codex / q_cli)
        ↓
   实际 CLI 工具 (在 tmux window 里跑)
```

## 支持的 Provider

| Provider | 启动命令 | 状态检测方式 |
|----------|---------|-------------|
| Kiro CLI (默认) | `kiro-cli chat --agent {profile}` | 检测 `❯` prompt |
| Claude Code | `claude --dangerously-skip-permissions` | 检测 `❯`/`>` prompt + `⏺` 响应标记 + spinner 字符 |
| Codex | `codex --full-auto` | 检测 `›` prompt + `•` bullet |
| Q CLI | `q chat` | 检测 Q 的 prompt |

## 核心机制

### 1. 进程管理 = tmux

- 每个 agent 是一个 tmux window（同一 session 下）
- 创建时注入 `CAO_TERMINAL_ID` 环境变量标识身份
- 用 `tmux pipe-pane` 把终端输出实时写到日志文件（`{terminal_id}.log`）

### 2. 输入 = tmux paste-buffer

- 用 `tmux load-buffer` + `paste-buffer -p`（bracketed paste）发送文本
- 避免了 send-keys 逐字符输入的问题和特殊字符转义
- Claude Code 需要双 Enter（bracketed paste 后进入多行模式）

### 3. 状态检测 = 正则匹配终端输出

每个 provider 实现 `get_status()`，读 tmux history 用正则判断：
- **IDLE**: 看到 prompt 字符（`❯`, `>`, `›`）
- **PROCESSING**: 看到 spinner 字符（`✶✢✽✻✳` + `…`）
- **COMPLETED**: 看到响应标记（`⏺`）+ prompt
- **ERROR**: 以上都没匹配到

### 4. 通信 = SQLite inbox + watchdog 文件监控

```
Agent-A 调 send_message(receiver_id, msg)
  → HTTP API → SQLite inbox 表写入 PENDING 消息
  → watchdog 监控 receiver 的 log 文件变化
  → log 变化时检查是否有 idle pattern
  → 如果 idle → 通过 tmux paste-buffer 投递消息
  → 更新状态为 DELIVERED
```

关键：不是轮询，是用 watchdog（inotify/kqueue）监控日志文件变化，然后快速检查 idle pattern，再做完整状态检测。两级过滤，性能不错。

### 5. 三种编排模式

| 模式 | 行为 | 适用场景 |
|------|------|---------|
| **handoff** | 创建 agent → 发任务 → 轮询等完成 → 取结果 → 退出 agent | 同步任务，要结果 |
| **assign** | 创建 agent → 发任务 → 立即返回 terminal_id | 异步并行，fire-and-forget |
| **send_message** | 往已有 agent 的 inbox 发消息 | 持续协作，多轮对话 |

### 6. Flow = 定时任务

用 cron 表达式调度 agent 任务，支持条件执行（先跑脚本判断是否需要执行）。

### 7. Agent Profile = markdown 文件

```yaml
---
name: developer
---
You are a developer agent...
```

system prompt 通过 `--append-system-prompt` 注入，MCP 配置通过 `--mcp-config` 注入。

## 数据模型

SQLite 三张表：
- **terminals**: id, tmux_session, tmux_window, provider, agent_profile, last_active
- **inbox**: id, sender_id, receiver_id, message, status(PENDING/DELIVERED/FAILED), created_at
- **flows**: name, schedule, agent_profile, provider, script, last_run, next_run, enabled

## 对我们目标的分析

### 满足的目标

| 目标 | 满足 | 说明 |
|------|------|------|
| AI 调 AI | ✅ | handoff/assign 创建子 agent |
| 结构化通信 | ✅ | MCP tool 调用，inbox 消息队列 |
| 完成检测 | ✅ | 正则匹配 terminal 输出，比纯轮询好 |
| 人可介入 | ✅ | `tmux attach` 切过去直接打字 |
| 人可观察 | ✅ | tmux window 列表，每个 agent 可见 |
| 多 AI 支持 | ✅ | 4 个 provider，统一接口 |
| 异步通信 | ✅ | inbox + watchdog，消息排队等 idle 投递 |

### 不满足 / 局限

| 问题 | 说明 |
|------|------|
| **依赖 tmux** | 我们在 nvim 里，用的是 nvim terminal，不是 tmux |
| **外部进程** | 需要跑 cao-server (FastAPI :9889)，不是 nvim 内嵌 |
| **状态检测靠正则** | 和我们现有方案一样，解析 ANSI 输出不可靠 |
| **通信不是实时推送** | inbox 是"等 idle 再投递"，不是真正的事件驱动 |

### 可借鉴的设计

1. **Provider 抽象** — 统一接口 `initialize/get_status/extract_last_message/exit_cli`，我们的 agent_api 也可以这样做
2. **Inbox + watchdog 模式** — 比纯轮询好很多。我们可以用 nvim 的 `on_stdout` 回调替代 watchdog
3. **三种编排模式** — handoff（同步等结果）/ assign（异步）/ send_message（给已有 agent 发消息），分类清晰
4. **bracketed paste 发送** — 用 paste-buffer -p 避免特殊字符问题，我们的 `send_to_terminal` 也应该用这个
5. **Agent Profile 作为 markdown** — 简单好用，system prompt + MCP 配置打包
6. **双 Enter 提交** — Claude Code bracketed paste 后需要双 Enter，这个细节很重要

### 与现有方案对比

| 维度 | CAO | 我们 (agent_api) | hcom |
|------|-----|-----------------|------|
| 进程隔离 | tmux window | nvim terminal | PTY 包装 |
| 输入方式 | tmux paste-buffer | nvim chansend | PTY 注入 |
| 状态检测 | 正则匹配 tmux history | 正则匹配 terminal buffer | hooks + 事件流 |
| 通信 | SQLite inbox + watchdog | 无（手动读 buffer） | SQLite 事件流 |
| 完成通知 | watchdog 文件监控 | 无 | hooks 实时回调 |
| 人介入 | tmux attach | 切 nvim tab | 切终端 |

### 结论

CAO 是目前看到的**工程化程度最高**的方案。架构分层清晰，provider 抽象好，inbox 通信机制实用。

但它绑定 tmux，我们绑定 nvim。核心思路可以直接搬：
- 把 tmux client → nvim terminal API
- 把 watchdog 文件监控 → nvim `on_stdout` 回调
- 把 FastAPI server → nvim 内 RPC 或直接 Lua 函数调用
- Provider 抽象、inbox 模型、三种编排模式直接复用

**最大启发：不需要 hcom 那样的 PTY 级别方案，tmux/nvim terminal + 正则状态检测 + inbox 消息队列就够用了。CAO 证明了这条路走得通。**

## 通信细节：全靠粘贴

所有通信的底层都是同一个动作：**往 tmux pane 里粘贴文本 + 按回车**。没有 socket、没有 pipe、没有文件通信。

```python
# 最终都走这里
tmux load-buffer -b xxx -      # 文本加载到 tmux buffer
tmux paste-buffer -p -b xxx    # 粘贴进目标 pane（bracketed paste）
sleep 0.3
tmux send-keys Enter           # 按回车
sleep 0.5
tmux send-keys Enter           # 再按一次（Claude Code 需要双 Enter）
```

### 为什么用 MCP

Claude Code 是黑盒，没法给它加代码。唯一让它"学会新能力"的方式就是 MCP。

启动时给 Supervisor 配 cao-mcp-server → 它就多了 handoff/assign/send_message 三个 tool → 当它觉得需要派子任务时自己决定调哪个。

Supervisor 不知道 tmux 的存在，它只知道"我有个 handoff tool"。

### handoff 取结果的方式

Worker 不主动"回传"任何东西。是 cao-server 主动去读的：

```
cao-server 轮询 worker 的 tmux history（每秒一次）
  → 正则看到 ⏺ + ❯ → 判定 COMPLETED
  → capture-pane 读 tmux buffer
  → extract_last_message_from_script() 提取 ⏺ 后面的文本
  → 作为 handoff() MCP tool 的返回值还给 Supervisor
```

Worker 完全不知道自己的输出被谁读了。它就是个普通 Claude Code 在跑。

### handoff 是阻塞的

Supervisor 调 handoff() 后，MCP tool call 就卡在那里，最多等 600 秒（可配置）。就跟调一个很慢的 API 一样。等 worker 干完，cao-server 读到结果，handoff() 才 return。

这也是为什么有 assign 模式 — 不等结果，立即返回 terminal_id。Worker 干完后通过 send_message 把结果发回 Supervisor 的 inbox。

```
handoff = 打电话，等对方说完挂了才能干别的
assign  = 发微信，发完就走，对方回了再看
```

### send_message 投递时机

不能在 agent 思考时往它终端里打字（会打断它），所以：

```
消息先存 SQLite inbox（PENDING）
  → watchdog 盯着目标 agent 的日志文件
  → 日志变化时快速检查 idle pattern
  → 确认 idle → 粘贴消息进终端
  → 更新状态为 DELIVERED
```

### 完整时序图（handoff）

```
  Supervisor           cao-server            tmux             Worker
  (Claude CLI)         (FastAPI)                              (Claude CLI)
      │                    │                   │                  │
  ① 调 MCP handoff()      │                   │                  │
      ├── HTTP POST ──────→│                   │                  │
      │                    │                   │                  │
      │               ② 创建 tmux window       │                  │
      │                    ├── create_window ──→│                  │
      │                    │                   │                  │
      │               ③ 粘贴启动命令            │                  │
      │                    ├── paste-buffer ───→├─────────────────→│
      │                    │   "claude ..."     │                  │
      │                    │                   │                  │
      │               ④ 轮询等 IDLE             │     ❯ _          │
      │                    ├── capture-pane ───→│                  │
      │                    │                   │                  │
      │               ⑤ 粘贴任务                │                  │
      │                    ├── paste-buffer ───→├─────────────────→│
      │                    │   "review ..."     │   ✽ Thinking…    │
      │                    │                   │                  │
      │  Supervisor 卡在这里等 MCP tool 返回     │                  │
      │                    │                   │                  │
      │               ⑥ 轮询等 COMPLETED        │                  │
      │                    ├── capture-pane ───→│   ⏺ 发现3个问题   │
      │                    │   看到 ⏺ + ❯       │   ❯ _            │
      │                    │                   │                  │
      │               ⑦ 提取 ⏺ 后面的文本       │                  │
      │                    │                   │                  │
      │               ⑧ 粘贴 /exit              │                  │
      │                    ├── paste-buffer ───→├─────────────────→│ exit
      │                    │                   │                  │
      │←── MCP 返回结果 ──┤                   │                  │
      │   "发现3个问题..."  │                   │                  │
```

一句话总结：**MCP 给 AI 装调度能力，tmux 粘贴当通信管道，正则判断对方忙不忙，SQLite 当信箱排队。**

## 相关文档

- [目标](ai-to-ai-goal.md)
- [方案对比](ai-to-ai-solutions.md)
- [架构现状](ai-to-ai-architecture.md)
- [hcom 研究](ai-to-ai-hcom.md)
