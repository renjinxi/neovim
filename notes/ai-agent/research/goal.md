# AI-to-AI 通信：目标

## 当前最优方案

**hcom** — PTY 注入 + hooks + SQLite 事件流。全部目标满足。详见 [hcom 研究](ai-to-ai-hcom.md)。

与 nvim 集成方式：`spawn_cli({cmd = "hcom claude"})` 即可。待研究完其他方向后实施验证。

## 当前阶段

**探索阶段** — 不急着落地，先摸清这个领域的全貌，看大家怎么做的，积累认知。

## 理想态

**AI 之间结构化实时通信 + 人可随时介入接管，两个都要。**

不管现在能不能做到，这就是最终想要的效果。

## 具体要求

### 1. AI 调 AI
- Claude Code（或其他 AI CLI）能启动另一个 AI 实例
- 主 AI 能给子 AI 下达任务、接收结果
- 通信要可靠，最好是结构化的（不是靠猜 terminal 输出）

### 2. 实时通信
- 主 AI 能实时感知子 AI 的状态（在跑、完成、出错）
- 不依赖轮询猜测，有明确的完成信号
- 支持流式获取子 AI 的输出

### 3. 人可介入
- 人能随时切过去看子 AI 在干什么
- 人能直接打字接管，就像正常用 `:AI` 一样
- 接管后 AI 也能重新拿回控制权
- **这是最关键的约束** — 纯后台进程方案（如 ACP）不满足这一点

### 4. 多 AI 工具支持
- 不只是 Claude，还要支持 Gemini、Codex 等
- 统一的调用接口，不同 CLI 只是参数不同

## 非目标

- 不是要做一个完整的 AI 编排框架
- 不是要替代 codecompanion / avante 这类插件
- 不需要复杂的多轮对话管理
- 重点是 nvim 内的实际可用性，不是协议完备性

## 约束

- 基于现有 agent_api.lua 扩展
- 在 nvim 内运行，利用 nvim 的 terminal/buffer 能力
- 人的体验优先于自动化的完美性

## 探索路线

已研究的方向：
- [x] codecompanion / avante / copilot 的通信方式 → ACP 协议
- [x] mc / team-anya 的 SDK-URL 模式 → WebSocket 反向连接
- [x] Codex App Server 架构 → 双向 JSON-RPC + thread/turn/item 模型

待研究的方向：
- [ ] Gemini CLI / Codex CLI 的程序化控制方式
- [ ] Claude CLI stream-json 模式
- [ ] 其他 AI 编排框架（LangGraph、CrewAI 等）
- [ ] 是否有人做到了"结构化 + 人可介入"的两全方案
