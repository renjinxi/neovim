# ACP 频道系统

nvim 作为 ACP client，启动多个 AI CLI agent，通过频道协作。

## 架构

```
你（nvim 前）
  │
  └── 主 agent (AcpChat)
        │  通过 nvim RPC 操控频道
        ▼
      频道 (bus)
        ├── 子 agent-1 (ACP stdin/stdout)
        └── 子 agent-2 (ACP stdin/stdout)
              │
              │ 干完活，发消息回频道
              │ terminal/create → bash → nvim --server --remote-expr
              ▼
            频道收到消息 → 解析 @mention → client:prompt() 推给主 agent
```

## 核心设计原则

- **agent 静默干活**：tool_call、流式输出等过程信息只写日志，不进频道
- **主动发言**：只有需要汇报（任务完成）或交互（提问、确认）时，agent 才发频道消息
- **bash 通信**：子 agent 通过 `terminal/create` → bash → `nvim --server --remote-expr` 发消息，不需要额外 MCP server
- **@mention 路由**：频道收到消息后解析 @，调 `client:prompt()` 推给被 @ 的 agent

## 为什么用 bash 而不是 MCP

子 agent 本来就会写代码、会调试。bash 命令报错它能看到 stderr，能自己改命令重试。MCP tool 报错它只能干等，没有自主修复的能力。bash 方案反而更符合 agent 的工作方式。

## 频道规则

- 所有消息进频道，人类在 buffer 里全程可见
- 有 `@agent-name` → 调 `client:prompt()` 推送给被 @ 的 agent
- 没有 @ → 只放在频道里，不推送
- 人类打字 → 同样规则

## 关键文档

- [roadmap.md](roadmap.md) — 里程碑规划
- [design/m1-redesign.md](design/m1-redesign.md) — M1 详细设计
