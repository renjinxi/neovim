# 方案：Claude Code /loop + MCP 通信

## 思路

用 Claude Code 的 `/loop` 定时任务 + MCP 通信（如 mcp_agent_mail），实现自动运转的 agent loop。

```
主 Claude:  /loop 1m fetch_inbox，有消息就处理，处理完 send_message
子 Claude:  /loop 1m fetch_inbox，有消息就处理，处理完 send_message

每个 AI 定时查收件箱 → 收到消息就干活 → 干完发消息 → 自动循环
人随时切 tab 打字介入
```

## 优势

- **极简** — 不需要 PTY 包裹、Rust 二进制、vt100 解析
- **只用现有能力** — Claude Code 原生 /loop + 任意 MCP Server
- **人可介入** — 每个 AI 都在正常 terminal 里
- **结构化通信** — MCP tool 调用

## 限制

- **不实时** — cron 最小粒度 1 分钟，不是 mid-turn 送达
- **只在空闲时触发** — AI 在忙的时候 /loop 不会中断它
- **仅 Claude Code** — Gemini/Codex 没有 /loop，这个方案只能在 Claude Code 之间用
- **session 级别** — 退出 Claude Code 就没了，不持久
- **3 天过期** — recurring task 自动过期，需要重建

## 和其他方案的对比

| | hcom | /loop + MCP |
|---|---|---|
| 实时性 | mid-turn 送达 | 1 分钟延迟 |
| 复杂度 | 高（PTY + hooks + Rust） | 低（原生功能 + MCP） |
| 跨 CLI | ✅ Claude/Gemini/Codex | ❌ 仅 Claude Code |
| 可靠性 | 依赖 vt100 解析 | 稳定（原生功能） |
| 人可介入 | ✅ | ✅ |

## 可以和 hcom 组合

```
hcom 负责：跨 CLI 通信、mid-turn 送达、状态检测
/loop 负责：兜底轮询、定时检查、简单场景
```

## 相关

- [hcom 研究](ai-to-ai-hcom.md) — PTY 方案（更强但更复杂）
- [落地方案](ai-to-ai-landing-plan.md) — agent_api + mcp_agent_mail
