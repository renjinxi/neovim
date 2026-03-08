# hcom 研究 — PTY 级别的跨 CLI Agent 通信

来源: https://github.com/aannoo/hcom
技术栈: Rust, SQLite, vt100, PTY

## 项目定位

让 Claude Code、Gemini CLI、Codex、OpenCode 在不同终端之间通信。不是 AI，是一个 PTY 代理层。

## 核心魔法：PTY 注入

hcom 不直接启动 claude，而是用 PTY 包裹它：

```
你 → hcom → PTY master → PTY slave → claude
      ↑
      hcom 坐在中间，能：
      1. 读屏幕（知道 claude 在干嘛）
      2. 注入按键（模拟人打字）
      3. 检测状态（空闲？等审批？在忙？）
```

## 消息送达流程（mid-turn）

```
Agent-A: hcom send @luna -- "review 完了"
  → 写入 SQLite
  → TCP 短连接唤醒 luna 的 DeliveryLoop
  → DeliveryLoop 检查 gate 条件：
      agent 空闲？ 没有权限弹窗？ 用户没在打字？ 输入框空？
  → 全部通过 → 注入 "<hcom>" 到 PTY stdin
  → 注入回车 "\r"
  → Claude 的 UserPromptSubmit hook 触发
  → hook 检测到 <hcom> → 从 DB 读未读消息
  → 通过 additionalContext 注入 Claude 上下文
  → Claude 看到消息，开始处理
```

## 状态检测（纯终端信号，不是 AI）

| 检测项 | 方法 |
|---|---|
| agent 空闲 | vt100 解析，输入框有 dim 属性 = placeholder = 空闲 |
| 权限弹窗 | OSC9 转义序列 |
| 用户在打字 | PTY master 端输入流 + cooldown |
| 消息已处理 | DB 的 last_event_id 是否前进 |

## SQLite 核心表

- `instances` — agent 注册表（name, status, tool, pid, directory...）
- `events` — 事件流（message/status/life）
- `notify_endpoints` — TCP 端口注册（delivery loop 唤醒用）
- `events_fts` — 全文搜索

## 各 CLI 集成方式

| CLI | 集成方式 |
|---|---|
| Claude Code | settings.json hooks（9 个 hook 类型） |
| Gemini CLI | settings.json hooks |
| Codex | config.toml notify |
| OpenCode | TypeScript plugin |

## 关键能力

- **mid-turn 送达** — 不用等 agent 空闲，直接 PTY 注入
- **碰撞检测** — 30 秒内两个 agent 编辑同一文件 → 双方收到警告
- **TUI 仪表盘** — `hcom` 无参数启动，看所有 agent 状态
- **终端查看** — `hcom term luna` 看 agent 的屏幕
- **文字注入** — `hcom term inject luna "text" --enter`
- **spawn/fork/resume** — 管理 agent 生命周期
- **MQTT relay** — 跨设备同步
- **订阅系统** — agent 订阅特定事件自动响应

## 和其他方案的对比

| | agent_api | mcp_agent_mail | hcom |
|---|---|---|---|
| 通信层 | PTY stdin/stdout | MCP HTTP tool | PTY 注入 + hooks |
| 送达时机 | 手动 | 轮询 | 自动 mid-turn |
| 状态追踪 | 无 | 无 | 完整状态机 |
| 碰撞检测 | 无 | file_reservation | 自动检测 |
| 屏幕读取 | get_terminal_output | 无 | vt100 解析 |
| 依赖 | nvim API | MCP server | Rust 二进制 + hooks |

## 对我们目标的满足度

| 目标 | 满足 |
|---|---|
| AI 调 AI | ✅ hcom spawn + hcom send |
| 结构化通信 | ✅ SQLite 事件流 |
| 实时通信 | ✅ mid-turn PTY 注入 |
| 人可介入 | ✅ 每个 AI 在终端里，人随时打字 |
| 人可观察 | ✅ TUI + hcom term |
| 多 CLI | ✅ Claude/Gemini/Codex/OpenCode |
| 完成检测 | ✅ status 状态追踪 |
| 文件冲突 | ✅ 碰撞检测 |

**全部满足。目前发现的最理想方案。**

## 本质：PTY 层面的通信协议

hcom 在 PTY 层面搭了一套完整的通信协议：

```
传输层：PTY（模拟人打字）
寻址：  @name / @tag- / 广播
分组：  tag 机制（--tag api / --tag frontend）
存储：  SQLite 事件流
送达：  DeliveryLoop + gate 安全检测
发现：  自动注册，CVCV 命名（luna/nova/kira）
同步：  MQTT（跨设备）
```

和正经网络协议的对应关系：

```
TCP/IP:   网卡 → IP寻址 → 端口 → 数据包
hcom:     PTY  → @name  → hook → 消息注入
```

传输介质不是网线，是终端里的字符流。

## 分组寻址

```bash
hcom claude --tag api          # api 组
hcom claude --tag frontend     # frontend 组

hcom send @api- -- "发给 api 组所有人"
hcom send @luna -- "只给 luna"
hcom send -- "广播所有人"
```

agent 名字格式：`tag-name`（如 `api-luna`、`frontend-nova`）。

## 缺点

1. **脆弱** — 靠 vt100 转义序列判断状态，CLI 更新 UI 可能导致检测失效
2. **慢** — 注入流程是毫秒到秒级，不是真正的程序间通信
3. **不可靠** — gate 判断错误会打断 agent 或送不进去
4. **只能传文本** — PTY 是字符流，无法传结构化数据/文件/二进制
5. **依赖 hooks** — mid-turn 送达靠各 CLI 的 hook 系统，没 hooks 就退化成轮询
6. **本质是 hack** — 模拟人打字，不是正式的通信协议，天花板在那里

## 与 nvim 集成

最简方式：
```lua
spawn_cli({cmd = "hcom claude --tag myproject", name = "worker"})
```

hcom 是透传的，人切 tab 过去还是能直接打字。
