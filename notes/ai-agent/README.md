# AI Agent — 多 Agent 协作系统

nvim 作为中枢，调度多个 CLI AI（Claude/Codex/Gemini）协作完成任务。

## 现状

- agent_api.lua 提供 RPC API：spawn 终端、发文字、文件任务系统
- task_watcher.lua 用 fs_event 监听任务完成
- 文件通信：task.md / status / result.md

## 目录结构

```
research/    ← 前期调研（各方案对比、源码研究）
design/      ← 设计文档（当前实现的架构、API、迭代记录）
reference/   ← 参考资料
```

## 关键文档

- [design/task-system.md](design/task-system.md) — 文件任务系统架构、API、TODO
- [design/session-bus.md](design/session-bus.md) — Session Bus：多 agent 协作运行时（构想阶段）
- [research/goal.md](research/goal.md) — 目标和最优方案结论
- [research/architecture.md](research/architecture.md) — 当前通信架构
- [research/solutions.md](research/solutions.md) — 方案对比（含三家 CLI 全貌）
- [research/hcom.md](research/hcom.md) — hcom 方案（当前最优参考）
- [research/sdk-url-protocol.md](research/sdk-url-protocol.md) — Claude Code WS 协议完整文档
- [research/gemini-cli.md](research/gemini-cli.md) — Gemini CLI 程序化控制（ACP/A2A/SDK）
- [research/acp-plan.md](research/acp-plan.md) — ACP 统一对接方案

## 调试

日志位置：`~/.ai-tasks/{nvim-pid}/debug.log`

```bash
# 查看当前 nvim 实例的 task 日志
cat ~/.ai-tasks/$(pgrep -f nvim | head -1)/debug.log
```
