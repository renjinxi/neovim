# ACP 频道系统

nvim 作为 ACP client，启动多个 AI CLI agent，通过频道协作。

## 架构

```
你（nvim 前）
  │
  └── 主 agent (AcpChat)
        │  ACP stdin/stdout
        ▼
      频道 (bus)
        ├── 子 agent-1 (ACP stdin/stdout)
        └── 子 agent-2 (ACP stdin/stdout)
              │
              │ 干完活，发消息回频道
              │ terminal/create → bash → nvim --server --remote-expr
              ▼
            频道收到消息
              → 渲染到频道 buffer（人类可见）
              → 解析 @mention → 路由推送
              → @agent-N → client:prompt()
              → @main → 推送给主 Claude
```

## 核心设计原则

- **所有消息过频道**：main 发任务、子 agent 回复、人类输入，全部经过 bus:post()
- **agent 静默干活**：tool_call、流式输出等过程信息只写 agent chat_buf，不进频道
- **主动发言**：只有需要汇报或交互时，agent 才发频道消息
- **bash 通信**：子 agent 通过 terminal/create → bash → nvim --remote-expr 发消息
- **@mention 路由**：解析 @，推送给对应 agent 或 main

## 为什么用 bash 而不是 MCP

子 agent 本来就会写代码、会调试。bash 命令报错它能看到 stderr，能自己改命令重试。MCP tool 报错它只能干等，没有自主修复的能力。

## 当前状态

P0（基础通信）✅ → P1（频道协作）90% → P2（可观测性）✅

详见 [roadmap.md](roadmap.md)。

## 关键文档

- [roadmap.md](roadmap.md) — 里程碑规划 + 已完成工作
- [design/m1-redesign.md](design/m1-redesign.md) — M1 详细设计（历史文档）
