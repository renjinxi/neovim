# M1 设计：频道协作

## 目标

子 agent 静默干活，完成后主动发消息回频道，频道按 @mention 路由推送给主 agent。

## 消息流

```
[主 agent] @子agent-1 review auth 模块 @子agent-2 review payment 模块
[子agent-1] @主agent auth 模块 review 完成，发现 3 个问题（附摘要）
[子agent-2] @主agent payment 模块没问题
[主 agent]  @子agent-1 第 2 个问题需要修复，其他可以忽略
[子agent-1] @主agent 已修复
```

频道里不会出现：
```
[子agent-1] 🔧 Read file
[子agent-1] → Read file: completed
[子agent-1] 我正在看 auth 模块的代码...
```

## 子 agent 怎么发消息

子 agent 通过 `terminal/create` → bash → `nvim --server` 发消息，不需要额外 MCP server。

**为什么用 bash**：bash 命令报错子 agent 能看到 stderr，能自己改命令重试。MCP tool 报错它只能干等。bash 方案更符合 agent 的工作方式。

子 agent 启动时，system prompt 注入：

```
你在一个协作频道里。任务完成或需要汇报时，执行以下命令发消息：

nvim --server "$NVIM_LISTEN_ADDRESS" --remote-expr \
  'luaeval("require(\"acp.rpc\").bus_post(vim.fn.json_encode({from=\"AGENT_NAME\",text=\"消息内容\"}))")'

规则：
- 任务完成：发 "@主agent 任务完成，结果是..."
- 遇到问题：发 "@主agent 遇到问题，需要..."
- 过程信息（读文件、写代码等）不发频道
```

## 频道路由逻辑

```
收到 bus_post 消息
  → 写入频道 buffer（人类始终可见）
  → 解析 @mention
  → 有 @ → client:prompt() 推给被 @ 的 agent
  → 没有 @ → 只写频道，不推送
```

## 需要改的文件

### bus.lua
`post()` 方法加路由：收到消息后解析 @mention，调对应 agent 的 `client:prompt()` 推送。

### adapter.lua
子 agent 启动时（`session/new`）注入 system prompt，包含：
- 频道使用说明
- bash 命令模板（含 `AGENT_NAME` 替换为实际 agent 名）
- `NVIM_LISTEN_ADDRESS` 说明

### rpc.lua
日志路径从 `/tmp/acp-bus.log` 改到 `~/.config/nvim/logs/acp-rpc.log`。
