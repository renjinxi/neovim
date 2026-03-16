# AGENTS.md

本仓库的核心开发方向是 **ACP（Agent Communication Protocol）多 AI 协作系统**。

## 你应该知道的

1. **ACP 是主线**：`lua/acp/` 是活跃开发区，其余是标准 Neovim 配置（相对稳定）
2. **问题清单**：`notes/acp-channel/issues.md` 是所有 ACP 问题的 source of truth
3. **架构文档**：`notes/acp-channel/design/architecture-redesign.md` 描述了完整架构设计
4. **中文代码注释**：这是刻意的，保持中文

## ACP 模块导航

| 模块 | 职责 | 改动频率 |
|------|------|----------|
| `channel.lua` | 频道核心：消息流、agent 管理、路由分发 | 高 |
| `scheduler.lua` | agent 调度：prompt 队列、main 推送、idle 通知 | 高 |
| `channel_view.lua` | 频道 UI：buffer 渲染、winbar、输入框 | 中 |
| `chat.lua` | 1v1 Chat UI：独立对话窗口 | 中 |
| `client.lua` | ACP 协议客户端：握手、prompt、流式接收 | 低（已稳定） |
| `router.lua` | @mention 路由解析 | 低 |
| `adapter.lua` | adapter 配置（claude/gemini/codex） | 低 |
| `init.lua` | 公共 API + `:Acp` 命令注册 | 随功能增长 |
| `rpc.lua` | nvim RPC 入口，供外部进程调用 | 随功能增长 |
| `commands.lua` | `/` 输入框命令系统 | 随命令增加 |
| `task.lua` | 任务数据模型（M2 重点） | 待扩展 |
| `registry.lua` | 全局频道注册表 | 低 |
| `store.lua` | 频道持久化 | 低 |

## 当前阶段

M1（频道协作）已完成，正在规划 M2（任务层）。M2 核心目标：
- 轻量 task 对象（task_id, owner, status, artifacts）
- 结构化协作原语（assign/done/blocked/artifact RPC）
- 可观测性面板（`:Acp inspect`）

详见 `notes/acp-channel/roadmap.md`。

## 协作模式

本仓库通过 ACP 频道系统实现多 AI agent 协作开发。典型模式：
- **main agent**（人类的直接助手）负责协调调度，不写代码
- **子 agent**（claude/codex/gemini）在频道中接受任务、实现、互相 review
- 频道是共享消息空间，@mention 指定对话对象
- 人类通过频道 UI 随时介入

## 参考实现

协议层对齐了 [codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim) 的 ACP 实现。
