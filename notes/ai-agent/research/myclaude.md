# myclaude 研究 — 多 Agent 编排平台

来源: https://github.com/stellarlinkco/myclaude
技术栈: Go (codeagent-wrapper) + Python (hooks) + Shell
规模: ~27K 行代码，78 个 Go 源文件

## 项目定位

扩展 Claude Code 的多 agent 编排系统。核心思路：Claude Code 当指挥官（只规划不写码），通过 codeagent-wrapper 调度多个 AI 后端干活。

## 核心架构：两层分离

```
┌─────────────────────────────────────────┐
│  Claude Code（指挥官）                    │
│  - 规划、拆任务、验收                      │
│  - 绝不直接写代码                         │
│  - 通过 codeagent-wrapper 调度执行        │
└──────────────┬──────────────────────────┘
               │ 调用 CLI
               ↓
┌─────────────────────────────────────────┐
│  codeagent-wrapper（Go 写的统一调度器）    │
│  - 抽象 4 个 AI 后端                      │
│  - 并行任务执行 + 依赖解析                 │
│  - git worktree 隔离                     │
└──┬──────┬──────┬──────┬────────────────┘
   │      │      │      │
   ↓      ↓      ↓      ↓
 Codex  Claude  Gemini  OpenCode
```

## 多后端抽象

codeagent-wrapper 统一封装了 4 个 AI CLI：

| 后端 | 用途 | 特点 |
|------|------|------|
| Codex (OpenAI) | 代码分析、复杂逻辑 | 默认后端 |
| Claude | 推理、文档 | 通过 API |
| Gemini | UI/UX、快速迭代 | 通过 CLI |
| OpenCode | 开源替代 | 备选 |

每个后端有独立的：CLI 参数构建器、环境变量注入、JSON 流解析、stderr 噪音过滤。

## 6 种工作流模式

| 模式 | 思路 | 特点 |
|------|------|------|
| DO | 5 阶段（理解→澄清→设计→实现→完成） | 并行 agent、worktree 隔离 |
| OmO | 风险信号路由 | 智能选 agent，不是固定流水线 |
| BMAD | 敏捷开发（PO→架构→SM→开发→Review→QA） | 6 个角色、90 分质量门 |
| Requirements | 需求驱动（需求→实现→Review→测试） | 轻量版 BMAD |
| SPARV | 规格→计划→执行→审查→归档 | 每 2 步存档、3 次失败停止 |
| Harness | 长时间自主工作 | 进度检查点、失败恢复、团队协调 |

## Agent 间通信方式：Context Pack

**没有直接的 agent-to-agent 消息传递。**

通信靠"上下文包"传递：

```
## 原始用户请求
<原始需求>

## 上下文包
- 前面 agent 的输出
- 已知约束
- 仓库上下文

## 当前任务
<具体任务>

## 验收标准
<完成条件>
```

每个 agent 启动时收到完整的上下文包，包含之前所有 agent 的产出。
单向流动：指挥官 → agent，agent 之间不直接通信。

## 并行执行引擎

```
---TASK---
id: task_id
workdir: /path
backend: codex
agent: develop
dependencies: task1, task2
skills: golang-base-practices
---CONTENT---
任务描述
```

- 拓扑排序解析依赖
- 独立任务并发执行
- 每个任务可选不同后端
- 通过 `CODEAGENT_MAX_PARALLEL_WORKERS` 控制并发数

## Hook 系统（Claude Code 集成）

| Hook 类型 | 用途 |
|-----------|------|
| PreToolUse | 工具执行前拦截（如阻止危险命令） |
| PostToolUse | 工具执行后检查点 |
| Stop | 阻止未完成时退出 |
| SessionStart | 恢复时注入上下文 |
| TeammateIdle | 队友空闲时分配任务 |
| SubagentStop | 阻止子 agent 在任务未完时退出 |

关键 hook 实现：
- `pre-bash.py` — 危险命令拦截
- `harness-stop.py` — 任务未完不让退
- `harness-teammateidle.py` — 队友空闲时继续分配工作
- `harness-subagentstop.py` — 子 agent 工作未完不让停

## 状态持久化

- 任务状态文件（`.claude/do-tasks/`、`.sparv/`）
- 追加式进度日志（可 grep）
- JSON 状态（harness-tasks.json，含依赖关系）
- git worktree 隔离（每个任务独立分支）

## 对我们 AI-to-AI 目标的分析

### 满足的

| 目标 | 满足度 |
|------|--------|
| AI 调 AI | ✅ Claude Code 通过 codeagent-wrapper 调度多个 AI |
| 多 CLI 支持 | ✅ Codex/Claude/Gemini/OpenCode 四个后端 |
| 人可介入 | ⚠️ 有审批门，但子 agent 在后台跑，不是 terminal 里 |
| 结构化通信 | ⚠️ Context Pack 是结构化的，但是单向的 |
| 实时通信 | ❌ 没有实时通信，是批处理模式 |
| 人可切过去打字 | ❌ 子 agent 不在 terminal 里，人无法直接交互 |

### 核心差异

myclaude 的模式是 **"指挥官 + 执行者"**：
- Claude Code 是大脑，只规划不动手
- codeagent-wrapper 是手，调用各种 AI 后端执行
- agent 之间不直接通信，靠 Context Pack 传递上下文
- 子 agent 是一次性的：启动 → 干活 → 返回结果 → 结束

我们想要的是 **"多个大脑互相对话"**：
- 多个 AI 实例同时运行
- 互相发消息、协调
- 人可以随时切过去接管任何一个

### 值得借鉴的

1. **codeagent-wrapper 的多后端抽象** — 统一接口封装 4 个 AI CLI，很实用
2. **并行任务 + 依赖解析** — 拓扑排序 + 并发执行，工程质量高
3. **Hook 防退出机制** — Stop/TeammateIdle/SubagentStop 三个 hook 确保任务完成
4. **Context Pack 模式** — 虽然不是实时通信，但结构化上下文传递的设计很清晰
5. **git worktree 隔离** — 每个任务独立分支，安全可回滚
6. **质量门控** — 90 分以上才能进入下一阶段

### 不能直接用的

1. **子 agent 不在 terminal 里** — 人无法切过去直接打字交互
2. **单向通信** — 指挥官 → agent，agent 之间不能互相通信
3. **批处理模式** — 不是实时的，启动 → 等完成 → 读结果
4. **深度绑定 Claude Code** — Hook 系统只有 Claude Code 支持

## 和其他方案的对比

| | myclaude | hcom | 我们的 agent_api |
|---|---|---|---|
| 多后端 | ✅ 4 个 | ✅ 任意 CLI | ✅ 任意 CLI |
| 通信方式 | Context Pack（单向） | PTY 注入（双向） | terminal buffer（单向） |
| 人可介入 | 审批门 | 切 tab 打字 | 切 tab 打字 |
| 并行执行 | ✅ 依赖解析 | ❌ | ❌ |
| 实时通信 | ❌ | ✅ mid-turn | ❌ 轮询 |
| 状态追踪 | 文件 + JSON | SQLite | 无 |

## 结论

**帮助不大，技术深度一般。**

本质就是个多后端 CLI wrapper——拼命令行参数、收 stdout、返回结果。6 种工作流（BMAD/OmO/SPARV 等）主要是 prompt 模板，不是代码逻辑。工程量不小但核心技术含量低，跟 Codex 源码（50+ Rust crates、PTY 管理、沙箱、MCP 双向集成）完全不是一个级别。

对我们的 AI-to-AI 实时通信目标没有实质帮助：子 agent 是一次性调用，不是活着的终端进程，人切不过去，agent 之间不能互相通信。

唯一可参考的点：codeagent-wrapper 的多后端抽象接口设计。
