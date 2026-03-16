# Adapter Native Commands 调研

by codex1 | 2026-03-16

---

## 调研范围

目标是区分两层能力：

1. CLI/TUI 原生命令
例如 slash command、`resume` 子命令、checkpoint/restore。

2. ACP 会话能力
也就是 adapter 在 `initialize` 里实际广告的 `loadSession`、`sessionCapabilities` 等。

这两层不能混为一谈。很多命令在交互式 CLI 里存在，但 ACP client 未必能调用到。

---

## 一览结论

| Adapter | `compact` | `clear` | `session/load` | `session/resume` | `session/fork` | 备注 |
|---|---|---|---|---|---|---|
| Claude (`claude-agent-acp`) | 有 `/compact` | 未确认有稳定 slash `/clear`；ACP 未单独暴露 | 支持 | 支持 | 支持 | ACP 能力最完整 |
| Gemini (`gemini --acp`) | CLI 有 `/compress` | CLI 有 `/clear` | 支持 | CLI 有 `/resume`，但 ACP **未广告** `session/resume` | 未发现 | CLI 命令很多，但 ACP 暴露较少 |
| Codex (`codex-acp`) | 有 `/compact` | 未发现 | 支持 | CLI 有 `resume`，但 ACP **未广告** `session/resume` | CLI 有 `fork`，但 ACP **未广告** `session/fork` | ACP 层偏保守 |

---

## 1. Claude

### 1.1 CLI 层

本机 `claude --help` 显示：

- `-r, --resume [value]`
- `-c, --continue`
- `--fork-session`

说明 Claude CLI 本身支持恢复和 fork 语义。

`claude-agent-acp` README 说明它支持：

- Custom Slash commands
- Client MCP servers
- Interactive terminals

adapter 源码里还有对 `/compact` 的明确兼容注释，说明 Claude slash command 的 `/compact` 在 ACP 流里是被考虑过的。

### 1.2 ACP 层

本机直接 probe `claude-agent-acp` 的 `initialize`，返回：

```json
"agentCapabilities": {
  "loadSession": true,
  "sessionCapabilities": {
    "fork": {},
    "list": {},
    "resume": {}
  }
}
```

这说明 Claude ACP 层明确支持：

- `session/load`
- `session/resume`
- `session/fork`
- `session/list`

### 1.3 对 #20 的意义

Claude 是目前最适合把 ACP 原生 session 能力接到 UI 上的 adapter。

如果你们要优先做：

- `:Acp restore`
- `:Acp resume`
- `:Acp fork`

Claude 这条链路最完整。

---

## 2. Gemini

### 2.1 CLI 层

Gemini 本机安装包和 README 明确显示：

- 有 checkpointing
- 有 `/clear`
- 有 `/compress`（别名 `/summarize`）
- 有 `/restore`
- 有 `/resume`

本机源码证据：

- `clearCommand.js`: 清空屏幕和对话历史，并重置 chat/session
- `compressCommand.js`: 调 `tryCompressChat(...)`
- `restoreCommand.js`: 从 checkpoint 恢复工具调用和历史
- `resumeCommand.js`: 打开 session browser，恢复 auto-saved conversations

所以 Gemini CLI/TUI 本身的“清空、压缩、恢复”能力其实很丰富。

### 2.2 ACP 层

`gemini --acp` 源码里的 `initialize()` 返回：

```js
agentCapabilities: {
  loadSession: true,
  promptCapabilities: { image: true, audio: true, embeddedContext: true },
  mcpCapabilities: { http: true, sse: true }
}
```

关键点：

- 明确支持 `loadSession`
- **没有广告** `sessionCapabilities.resume`
- **没有广告** `sessionCapabilities.fork`

另外，Gemini ACP 的 `available_commands_update` 并不是把全部 TUI slash commands 暴露出来，而是只注册了一小组 headless ACP commands：

- `memory`
- `extensions`
- `init`
- `restore`

也就是说：

- CLI 里有 `/clear`、`/compress`、`/resume`
- 但 ACP mode 里这些并没有直接作为 ACP command 暴露

### 2.3 对 #20 的意义

Gemini 有两个“恢复”概念：

1. CLI/TUI 侧的 checkpoint / resume
2. ACP 侧的 `session/load`

对 ACP 客户端来说，目前可靠可接的是 `session/load`，不是 `/resume` 或 `/clear`。

如果你们做统一 UI，Gemini 这边应优先映射：

- `session/load`

而不是假设它也有：

- `session/resume`
- `/clear`
- `/compress`

这些更像 Gemini TUI 的内部命令，不是通用 ACP 能力。

---

## 3. Codex

### 3.1 CLI 层

本机 `codex --help` 显示：

- `resume`
- `fork`

本机 `codex-acp` README 明确列出支持的 slash commands：

- `/review`
- `/review-branch`
- `/review-commit`
- `/init`
- `/compact`
- `/logout`
- Custom Prompts

所以 Codex CLI / Codex ACP adapter 至少明确有 `/compact`。

### 3.2 ACP 层

本机直接 probe `codex-acp` 的 `initialize`，返回：

```json
"agentCapabilities": {
  "loadSession": true,
  "sessionCapabilities": {
    "list": {},
    "close": {}
  }
}
```

这说明 Codex ACP 当前明确支持：

- `session/load`
- `session/list`
- `session/close`

但 **没有广告**：

- `session/resume`
- `session/fork`

虽然 Codex 主 CLI 自己有 `resume` / `fork` 子命令，但 `codex-acp` 没把这两项暴露成 ACP capability。

### 3.3 对 #20 的意义

Codex 的情况和 Gemini 类似：

- CLI 原生命令比 ACP 暴露出来的能力更多
- ACP client 不能假设“CLI 有 resume，所以 ACP 也能 resume”

如果 UI 层统一做恢复，Codex 目前只能稳妥依赖：

- `session/load`
- `session/list`

不能直接依赖：

- `session/resume`
- `session/fork`

---

## 4. 关键差异总结

### 4.1 `compact`

- Claude：有 `/compact`
- Gemini：有 `/compress`，语义相当于 compact
- Codex：有 `/compact`

但这类命令大多是 adapter/CLI 命令，不是 ACP spec 的独立会话方法。

如果 ACP UI 要做“压缩上下文”，有两种路径：

1. 发 slash command
2. 走 adapter 自己的 command system

不能指望协议层有统一 `session/compact`。

### 4.2 `clear`

- Gemini CLI 明确有 `/clear`
- Claude：本次未找到同等级的一手 ACP/adapter 证据
- Codex：未找到 clear 命令

所以 `clear` 不是一个跨 adapter 的稳定公共能力。

如果要做统一 UI，建议不要先做成通用按钮。

### 4.3 `session/load`

- Claude：支持
- Gemini：支持
- Codex：支持

这是三家里最像“可统一抽象”的恢复能力。

### 4.4 `session/resume`

- Claude ACP：支持
- Gemini ACP：未广告
- Codex ACP：未广告

所以 `resume` 不能做成统一跨 adapter 的必备功能。

### 4.5 `session/fork`

- Claude ACP：支持
- Gemini ACP：未发现
- Codex ACP：未广告

同样不适合当作统一能力来设计。

---

## 5. 对 ACP 的建议

### 建议 1：M1 统一暴露 `session/load`，不要先统一 `resume/fork`

因为三家共同交集目前最稳定的是：

- `session/load`
- `session/list`（Codex/Claude 明确；Gemini 可通过自己的 session 体系做近似）

### 建议 2：`compact` 做成 adapter-specific action

不要抽象成 ACP 通用协议能力。

更合理的做法是：

- UI 层显示“Compact/Compress（若 adapter 支持）”
- Claude/Codex 走 `/compact`
- Gemini 走 `/compress`

### 建议 3：`clear` 暂时不要做统一入口

目前只有 Gemini 的本机证据最明确。Claude/Codex 没有同等确定性。

### 建议 4：文档里明确区分“CLI 命令”和“ACP capability”

否则很容易误判：

- “Codex CLI 有 resume” ≠ `codex-acp` 支持 `session/resume`
- “Gemini TUI 有 clear/compress” ≠ Gemini ACP client 能直接调用这些命令

---

## 6. 结论

如果只回答 #20 最重要的点：

1. 最值得统一接入的是 `session/load`
因为 Claude / Gemini / Codex ACP 都支持。

2. `resume` / `fork` 目前只有 Claude ACP 真正完整
不应设计成所有 adapter 都有。

3. `compact` 可以做，但必须按 adapter 分发
Claude/Codex 是 `/compact`，Gemini 是 `/compress`。

4. `clear` 现在不适合作为统一能力
至少目前证据只足够说明 Gemini CLI 有明确实现。

---

## 调研依据

本次主要基于本机已安装版本的一手材料：

- `claude --help`
- `codex --help`
- `claude-agent-acp` / `codex-acp` / `gemini --acp` 的 `initialize` 实测回包
- 本机安装包源码与 README：
  - `@zed-industries/claude-agent-acp`
  - `@google/gemini-cli`
  - `@zed-industries/codex-acp`

其中 ACP capability 的判断，以 `initialize` 实测回包和 adapter 源码为准，优先级高于 README 描述。
