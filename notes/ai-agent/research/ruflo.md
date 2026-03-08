# Ruflo (claude-flow) 研究

来源: https://github.com/ruvnet/ruflo

## 项目定位

AI Agent 编排平台，把 Claude Code 变成多 agent 协作系统。5800+ commits，215 个 MCP tools，60+ agent 类型。

## 核心架构

```
Ruflo 进程 (Node.js)
  ├── MCP Server (215 tools)     ← Claude Code 通过 MCP 调用
  ├── Queen Coordinator          ← 任务分解/分配
  ├── MessageBus (内存)          ← agent 间消息队列
  ├── Memory (SQLite + HNSW)    ← 知识记忆/向量搜索
  └── Consensus (Raft/Byzantine/Gossip)
```

关键：Ruflo 里的 "agent" 不是真正的 AI 进程，是内部的任务角色标签。真正干活的只有 Claude Code。

## 值得了解的概念

### 1. 协调与执行分离
Ruflo 只做编排不做执行。任务分解、状态追踪、记忆存储在 Ruflo 进程里，实际写代码跑命令由 Claude Code 完成。

### 2. MessageBus（消息总线）
内存中的高性能消息队列：
- 4 级优先级（urgent/high/normal/low）
- ACK 确认 + 超时重试
- 广播 + 点对点
- 问题：内存中，进程挂了就没了，人无法审计

### 3. 共享 Memory
SQLite + HNSW 向量索引：
- agent 通过 memory namespace 交换信息
- 比纯消息更灵活（可以存结构化知识、搜索相似内容）
- 持久化的，进程重启不丢

### 4. Hooks 集成
通过 Claude Code 的 hooks 机制非侵入式扩展：
- PreToolUse — 拦截工具调用
- PostToolUse — 学习模式
- UserPromptSubmit — 任务路由
- 局限：只有 Claude Code 支持，Gemini/Codex 没有

### 5. 三层模型路由
| 层 | 处理器 | 延迟 | 成本 |
|---|---|---|---|
| 1 | WASM 本地 | <1ms | $0 |
| 2 | Haiku (便宜模型) | ~500ms | $0.0002 |
| 3 | Sonnet/Opus | 2-5s | $0.003+ |

简单任务用便宜的，复杂任务才用贵的。

### 6. Swarm 拓扑
支持 hierarchical / mesh / ring / star / centralized 等拓扑结构。默认 15-agent 层级网格，按 domain 分组（queen/security/core/integration/support）。

## 局限性

1. **深度绑定 Claude Code** — Hooks 体系只有 Claude Code 支持，换 CLI 就废了
2. **通信不透明** — MessageBus 在内存里，人无法审计通信记录
3. **过度工程** — 134 个 skill、60+ agent 类型、215 个 MCP tools，大部分用不到
4. **不是真正的多 AI 协作** — 只有一个 AI 进程 + 一个协调进程，不是多个 AI 互相通信

## 对我们的价值

学到的概念：
- 消息总线（MessageBus）— agent 间异步通信的基础设施
- 共享记忆（Memory）— 比消息更灵活的信息交换方式
- 协调与执行分离 — 编排层不做执行，只做调度
- 模型路由 — 按任务复杂度选择不同成本的模型
- Hooks 自动触发 — 比 system prompt 约定更可靠（但不通用）

不适合直接用的原因：
- 绑定 Claude Code，不跨 CLI
- 通信不落盘，人无法审计
- 过度复杂
