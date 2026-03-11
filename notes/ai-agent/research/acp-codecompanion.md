# CodeCompanion.nvim ACP 实现研究

## 架构总览

CodeCompanion 把 adapter 分两类：`http`（直接调 API）和 `acp`（通过 CLI 子进程 + JSON-RPC）。ACP 部分完全独立于 HTTP 路径，核心文件：

```
lua/codecompanion/
├── acp/
│   ├── init.lua          # Connection 类 — 进程管理、JSON-RPC 收发、session 生命周期
│   ├── methods.lua       # RPC method 常量表
│   └── prompt_builder.lua # fluent API 构建 prompt，注册流式回调
├── adapters/acp/
│   ├── init.lua          # ACPAdapter 基类（resolve/extend/new）
│   ├── helpers.lua       # form_messages — 统一消息格式化
│   ├── claude_code.lua   # Claude Code adapter 定义
│   ├── gemini_cli.lua    # Gemini CLI adapter 定义
│   ├── codex.lua         # Codex adapter 定义
│   └── ...               # goose/kiro/kimi_cli/opencode 等
├── interactions/chat/acp/
│   ├── handler.lua       # ACPHandler — chat buffer 与 ACP 的桥接层
│   ├── formatters.lua    # tool call 输出格式化（单行摘要）
│   ├── request_permission.lua # 权限请求 UI（confirm 对话框 / diff 预览）
│   ├── commands.lua      # ACP slash commands 注册与查询
│   └── fs.lua            # fs/read_text_file, fs/write_text_file 实现
└── utils/jsonrpc.lua     # JSON-RPC 2.0 工具（request/result/error/notification + LineBuffer + IdGenerator）
```

## 1. ACP 进程 Spawn 与通信

### 进程启动

`Connection:start_agent_process()` 用 `vim.system()` 启动子进程：

```lua
vim.system(
  adapter.command,  -- e.g. {"claude-agent-acp"} 或 {"gemini", "--experimental-acp"}
  {
    stdin = true,
    cwd = vim.fn.getcwd(),
    env = adapter.env_replaced,
    stdout = schedule_wrap(function(err, data)
      self:buffer_stdout_and_dispatch(data)
    end),
    stderr = schedule_wrap(...),
  },
  schedule_wrap(function(obj) self:handle_process_exit(obj.code, obj.signal) end)
)
```

关键点：
- 用 `vim.system` 而非 `vim.fn.jobstart`，更现代
- stdin 写入、stdout 读取，纯 stdio JSON-RPC
- `schedule_wrap` 确保回调在主线程执行

### JSON-RPC 消息处理

stdout 数据通过 `LineBuffer` 按 `\n` 分割成完整行，每行一个 JSON-RPC 消息：

```lua
-- LineBuffer 核心逻辑
function LineBuffer:push(data, callback)
  self._buffer = self._buffer .. data
  while true do
    local newline_pos = self._buffer:find("\n")
    if not newline_pos then break end
    local line = self._buffer:sub(1, newline_pos - 1):gsub("\r$", "")
    self._buffer = self._buffer:sub(newline_pos + 1)
    if line ~= "" then callback(line) end
  end
end
```

消息分发逻辑在 `handle_rpc_message`：
- 有 id 无 method → response，存入 `pending_responses`
- 有 method → notification/request，走 DISPATCH 表

### 同步等待模式

`send_rpc_request` 发送后用 `vim.wait` 轮询 `pending_responses`：

```lua
function Connection:wait_for_rpc_response(id)
  local start_time = uv.hrtime()
  local timeout = self.adapter_modified.defaults.timeout * 1e6
  while uv.hrtime() - start_time < timeout do
    vim.wait(10)  -- 10ms 轮询
    if self.pending_responses[id] then
      local result, err = unpack(self.pending_responses[id])
      self.pending_responses[id] = nil
      return err and nil or result
    end
  end
end
```

这个模式用于 initialize、authenticate、session/new 等必须同步完成的操作。

## 2. ACP 协议流程

### 完整生命周期

```
connect_and_initialize()
  ├── start_agent_process()     # spawn CLI
  ├── send_rpc_request("initialize", params)  # 握手
  ├── _authenticate()           # 可选认证
  ├── _establish_session()      # session/new 或 session/load
  └── apply_default_model()     # 设置默认模型
```

### ACP Methods 常量

```lua
INITIALIZE = "initialize"
AUTHENTICATE = "authenticate"
SESSION_NEW = "session/new"
SESSION_LOAD = "session/load"
SESSION_PROMPT = "session/prompt"
SESSION_UPDATE = "session/update"          -- agent → client 通知
SESSION_REQUEST_PERMISSION = "session/request_permission"  -- agent → client 请求
SESSION_CANCEL = "session/cancel"
SESSION_SET_MODE = "session/set_mode"
SESSION_SET_MODEL = "session/set_model"
FS_READ_TEXT_FILE = "fs/read_text_file"    -- agent → client 请求
FS_WRITE_TEXT_FILE = "fs/write_text_file"  -- agent → client 请求
```

### session/update 子类型

```
agent_message_chunk  — 文本流式输出
agent_thought_chunk  — 思考过程
tool_call            — 工具调用开始
tool_call_update     — 工具调用状态更新
plan                 — 计划
available_commands_update — slash commands 更新
current_mode_update  — 模式切换
```

## 3. Adapter Pattern

每个 ACP adapter 就是一个 table，结构统一：

```lua
{
  name = "claude_code",
  formatted_name = "Claude Code",
  type = "acp",
  roles = { llm = "assistant", user = "user" },
  opts = { vision = true },
  commands = {
    default = { "claude-agent-acp" },
    yolo = { "claude-agent-acp", "--yolo" },
  },
  defaults = {
    mcpServers = {},
    timeout = 20000,
  },
  env = { CLAUDE_CODE_OAUTH_TOKEN = "CLAUDE_CODE_OAUTH_TOKEN" },
  parameters = {
    protocolVersion = 1,
    clientCapabilities = { fs = { readTextFile = true, writeTextFile = true } },
    clientInfo = { name = "CodeCompanion.nvim", version = "1.0.0" },
  },
  handlers = {
    setup = function(self) return true end,
    auth = function(self) ... end,
    form_messages = function(self, messages, capabilities)
      return helpers.form_messages(self, messages, capabilities)
    end,
    on_exit = function(self, code) end,
  },
}
```

不同 CLI 的差异仅在 `commands` 和 `env`：
- Claude Code: `{"claude-agent-acp"}`
- Gemini CLI: `{"gemini", "--experimental-acp"}`
- Codex: `{"codex-acp"}`
- Goose: `{"goose", "acp"}`

config 中注册：`adapters.acp.claude_code = "claude_code"` → 自动 require 对应文件。

## 4. 流式输出处理

### PromptBuilder — Fluent API

```lua
connection:session_prompt(messages)
  :on_message_chunk(fn)      -- 文本 chunk
  :on_thought_chunk(fn)      -- 思考 chunk
  :on_tool_call(fn)          -- 工具调用
  :on_tool_update(fn)        -- 工具状态更新
  :on_permission_request(fn) -- 权限请求
  :on_complete(fn)           -- 完成
  :on_error(fn)              -- 错误
  :with_options(opts)
  :send()
```

`send()` 发送 `session/prompt` RPC 请求，后续通过 `session/update` notification 流式接收。

### ACPHandler — Chat Buffer 桥接

`ACPHandler` 是 chat buffer 和 ACP Connection 之间的桥接层：

```lua
-- 文本 chunk → 直接追加到 buffer
function ACPHandler:handle_message_chunk(content)
  table.insert(self.output, content)
  self.chat:add_buf_message(
    { role = "llm", content = content },
    { type = "LLM_MESSAGE" }
  )
end

-- tool call → 格式化为单行摘要，支持就地更新
function ACPHandler:process_tool_call(tool_call)
  local content = formatter.tool_message(tool_call, self.chat.adapter)
  -- 如果已有该 tool 的行，就地更新；否则新增一行
  if ACPHandlerUI[self.chat.bufnr][id] then
    self.chat:update_buf_line(match.line_number, content, { status = tool_call.status })
  else
    local line_number, icon_id = self.chat:add_buf_message(...)
    ACPHandlerUI[self.chat.bufnr][id] = { line_number = line_number, icon_id = icon_id }
  end
end
```

## 5. Chat Buffer 渲染

### Buffer 创建

- 普通 `nvim_create_buf(true, true)` 创建 scratch buffer
- filetype 设为 `codecompanion`（触发 ftplugin）
- 窗口支持 float/vertical/horizontal/tab 四种布局

### 消息渲染

- 用 `## Role` 作为 H2 header 分隔不同角色
- header 后面用 extmark 画分隔线（`CodeCompanionChatSeparator` hl group）
- 消息内容直接作为 markdown 文本写入 buffer
- buffer 的 filetype 是 `codecompanion`，但内容是 markdown 格式

### Builder 模式

Builder 管理三种 formatter：
- `Standard` — 普通 LLM 文本输出
- `Reasoning` — 思考过程（可折叠）
- `Tools` — 工具调用（单行 + 状态图标 extmark）

写入流程：
1. 判断是否需要新 header（角色切换时）
2. 选择 formatter 格式化内容
3. `nvim_buf_set_text` 追加到 buffer 末尾
4. 应用 extmark（图标、折叠等）
5. 自动滚动到底部

### 输入框

没有独立输入框。用户直接在 `## User` header 下面编辑 buffer 内容，按快捷键提交。buffer 在 LLM 响应时 lock（`modifiable = false`），完成后 unlock。

### 流式输出

每个 chunk 到达时：
1. `add_buf_message` → `Builder:add_message` → `nvim_buf_set_text` 追加
2. `ui:move_cursor` 自动滚动（除非用户手动移动了光标）
3. tool call 支持就地更新同一行（通过缓存 line_number）

## 6. 权限请求处理

两种模式：
1. **Diff 预览**：如果 tool_call 包含 diff 内容，打开 diff UI，用户按快捷键 allow/reject
2. **Confirm 对话框**：否则用 `vim.fn.confirm` 弹出选择

快捷键在 config 中定义：`g1` allow_always, `g2` allow_once, `g3` reject_once, `g4` reject_always

## 7. 文件系统请求

Agent 可以通过 ACP 请求读写文件：
- `fs/read_text_file` → 读文件内容返回给 agent
- `fs/write_text_file` → 写文件，优先写入已打开的 buffer，否则直接写磁盘

## 可搬用的模式和代码

### 直接可用

1. **jsonrpc.lua** — 完整的 JSON-RPC 2.0 工具库（~170行），包含 LineBuffer 和 IdGenerator
2. **ACP methods 常量表** — 协议方法名
3. **Adapter 定义模式** — 每个 CLI 一个 table，差异仅在 command/env

### 值得参考

1. **Connection 类的 vim.system + vim.wait 同步模式** — 初始化阶段同步等待，prompt 阶段异步流式
2. **PromptBuilder fluent API** — 注册回调链式调用，比事件系统更直观
3. **tool call 就地更新** — 缓存 line_number，后续 update 同一行而非追加新行
4. **权限请求的 diff UI** — 编辑类操作展示 diff 让用户决策

### 与我们的差异

- CodeCompanion 的 chat buffer 是 markdown buffer + extmark，不是终端
- 我们的方案是终端内嵌 + RPC 控制，不需要自己渲染消息
- 但 ACP 协议层（Connection + JSON-RPC）可以直接复用
- 如果我们要做非终端的 chat UI，Builder + Formatter 模式值得参考
