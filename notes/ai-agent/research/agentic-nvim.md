# agentic.nvim 研究笔记

仓库：https://github.com/carlos-algms/agentic.nvim
克隆位置：`/tmp/acp-research/agentic.nvim`

## 核心架构

### 分层结构

```
acp/                    # ACP 协议层
├── acp_transport.lua   # stdio 传输（uv.spawn + pipe）
├── acp_client.lua      # JSON-RPC 客户端（基类）
├── acp_payloads.lua    # 消息构造（text/image/audio/resource_link）
├── acp_health.lua      # CLI 可用性检测
├── agent_instance.lua  # 进程单例管理（每 provider 一个进程）
├── agent_modes.lua     # agent mode 切换（如 claude 的 plan/code 模式）
├── slash_commands.lua  # /command 补全
└── adapters/           # 各 CLI 适配器（继承 acp_client）

session_registry.lua    # tab_page_id -> SessionManager 映射（weak table）
session_manager.lua     # 核心胶水：串联 agent、widget、message_writer、permission
session_restore.lua     # 会话持久化/恢复

ui/
├── chat_widget.lua     # 窗口容器（6 个 buffer：chat/input/code/files/diagnostics/todos）
├── widget_layout.lua   # 窗口布局（right/left/bottom 三种位置）
├── message_writer.lua  # chat buffer 渲染引擎（extmark 驱动）
├── permission_manager.lua  # 权限请求 UI（数字键选择）
├── chat_history.lua    # 会话历史存储（JSON 文件）
├── diff_preview.lua    # 编辑 diff 预览（inline/split）
├── tool_call_diff.lua  # diff 解析
├── file_list.lua       # 附加文件列表
├── code_selection.lua  # 代码选区上下文
├── diagnostics_*.lua   # 诊断信息上下文
├── todo_list.lua       # agent plan 展示
└── ...
```

### 关键设计决策

1. **一个 agent 进程服务多个 session**：`agent_instance.lua` 按 provider name 缓存进程，不同 tab 共享同一进程，通过 `session/new` 创建独立会话
2. **tab page = session**：`session_registry.lua` 用 weak table 映射 `tab_page_id -> SessionManager`，tab 关闭自动清理
3. **adapter 模式**：每个 CLI 的差异通过继承 `ACPClient` 覆写 `__handle_tool_call` / `__handle_tool_call_update` 处理

## ACP 协议通信

### 传输层（acp_transport.lua）

- `uv.spawn` 启动 CLI 进程，stdio pipe 通信
- 继承完整父进程环境变量 + 注入 `NODE_NO_WARNINGS=1`, `IS_AI_TERMINAL=1`
- stdout 按 `\n` 分割，每行一个 JSON-RPC 消息
- stderr 捕获但不阻断，已知无害消息模式过滤
- 支持自动重连（可配置次数）

### 协议流程

```
Client                          Agent (CLI)
  |--- initialize ----------------->|   # protocolVersion, clientInfo, clientCapabilities
  |<-- result (agentCapabilities) --|
  |--- session/new ---------------->|   # cwd, mcpServers
  |<-- result (sessionId, modes) ---|
  |--- session/prompt -------------->|  # sessionId, prompt (Content[])
  |<-- session/update (streaming) --|   # agent_message_chunk / tool_call / tool_call_update / plan / ...
  |<-- session/request_permission --|   # 需要用户确认的操作
  |--- result (outcome) ----------->|
  |--- session/cancel -------------->|  # 停止生成 or 销毁 session
  |--- session/set_mode ------------>|  # 切换 agent mode
  |--- session/load ---------------->|  # 恢复历史 session（需 agent 支持）
```

### session/update 消息类型

| sessionUpdate | 说明 |
|---|---|
| agent_message_chunk | agent 文本流 |
| agent_thought_chunk | thinking 流 |
| tool_call | 工具调用开始（kind: read/edit/execute/think/fetch/...） |
| tool_call_update | 工具调用状态更新（含 diff、body） |
| plan | todo 列表（entries: content/priority/status） |
| available_commands_update | 可用 slash commands |
| current_mode_update | mode 变更通知 |
| usage_update | token 用量/费用 |

### prompt 内容格式（Content[]）

- `text` — 纯文本
- `image` — base64 图片（mimeType + data）
- `audio` — base64 音频
- `resource_link` — 文件引用（`file://` URI）

## 支持的 CLI 及启动参数

| Provider | command | args | 备注 |
|---|---|---|---|
| claude-agent-acp | `claude-agent-acp` | 无 | 默认 provider，新版 Claude Code ACP |
| claude-acp | `claude-code-acp` | 无 | 旧版 Claude Code ACP |
| gemini-acp | `gemini` | `--experimental-acp` | Gemini CLI |
| codex-acp | `codex-acp` | 无 | Zed 出品的 codex-acp binary |
| opencode-acp | `opencode` | `acp` | OpenCode CLI |
| cursor-acp | `cursor-agent-acp` | 无 | Cursor Agent |
| auggie-acp | `auggie` | `--acp` | Auggie CLI |
| mistral-vibe-acp | `vibe-acp` | 无 | Mistral Vibe |

每个 adapter 的差异主要在 tool_call 消息解析：
- **Claude**：rawInput 里有 file_path/new_string/old_string/command/subagent_type/skill 等
- **Gemini**：permission 请求里携带 diff，需要合成 tool_call；不发 cancel update
- **Codex**：rawInput 有 parsed_cmd/action 结构
- **OpenCode**：tool_call 几乎为空，数据全在 tool_call_update 的 rawInput 里
- **Cursor**：available_commands 在 session 创建前就发，需要缓存

## Chat Buffer 渲染

### 窗口结构

ChatWidget 创建 6 个 scratch buffer（`buftype=nofile`），按需显示：

```
┌─────────────────────────────┐
│ chat (AgenticChat)          │  markdown filetype，treesitter 渲染
│                             │
│                             │
├─────────────────────────────┤
│ todos (AgenticTodos)        │  可选，显示 agent plan
├─────────────────────────────┤
│ code (AgenticCode)          │  可选，显示选中代码
├─────────────────────────────┤
│ files (AgenticFiles)        │  可选，显示附加文件
├─────────────────────────────┤
│ diagnostics                 │  可选，显示诊断信息
├─────────────────────────────┤
│ input (AgenticInput)        │  唯一可编辑 buffer
└─────────────────────────────┘
```

### MessageWriter 渲染机制

- 普通消息：`nvim_buf_set_lines` 追加
- 流式 chunk：`nvim_buf_set_text` 追加到最后一行末尾
- tool_call block：用 extmark（NS_TOOL_BLOCKS）标记范围，后续 update 通过 extmark 定位并替换
- diff 高亮：专用 namespace（NS_DIFF_HIGHLIGHTS），支持 old/new/modification 三种
- 状态图标：extmark virt_text overlay
- 自动滚动：检测光标距底部距离，threshold 内自动 `G0zb`

### 输入框

- 普通 buffer，markdown filetype，treesitter 高亮
- `<CR>` / `<C-s>` 提交
- `/` 开头触发 slash command 补全（completefunc）
- 支持图片粘贴（`<C-v>` insert mode）
- 提交后清空 input + code + files + diagnostics buffer

### 权限请求

- PermissionManager 维护请求队列，串行处理
- 在 chat buffer 末尾追加选项文本，绑定数字键（1/2/3/4）
- 新消息到来时 reanchor（删除旧按钮，重新追加到末尾）
- 选项类型：allow_once / allow_always / reject_once / reject_always

## 多 Agent 支持

**没有多 agent 并行 / 频道 / 群聊概念。**

- 每个 tab page 一个 session，一个 provider
- 可以通过 `switch_provider` 切换 provider（保留聊天历史，创建新 ACP session）
- 可以通过 `new_session` 重置当前 tab 的 session
- agent_instance 按 provider 缓存进程，不同 tab 可以用不同 provider

## 可直接复用的部分

### 高价值（核心协议层）

1. **acp_transport.lua** — stdio spawn + JSON-RPC 解析，几乎可以原样搬。关键点：
   - 环境变量继承 + 覆盖
   - stdout 按行分割 JSON
   - stderr 过滤
   - 进程生命周期管理

2. **acp_client.lua** — ACP 协议状态机（connect -> initialize -> ready -> session/new -> prompt），包含完整的类型定义。900+ 行但大部分是 LuaLS 类型注解，实际逻辑 ~300 行

3. **acp_payloads.lua** — Content 构造（text/image/audio/resource_link），文件 MIME 检测

4. **adapters/** — 各 CLI 的消息差异处理。如果只对接 Claude，只需 `claude_agent_acp_adapter.lua`

### 中等价值（可参考设计）

5. **session_manager.lua** — 胶水层设计模式：handlers 回调注册、消息路由、上下文组装（code selection + files + diagnostics -> prompt）

6. **permission_manager.lua** — 权限请求队列化处理 + UI 锚定

7. **message_writer.lua** — extmark 驱动的 tool_call block 渲染，支持增量更新

### 低价值（UI 偏好差异大）

8. **chat_widget.lua / widget_layout.lua** — 多 buffer 侧边栏布局，和我们的浮动窗口方案差异大
9. **diff_preview.lua** — 编辑 diff 预览，功能完善但实现复杂

## 与我们方案的对比

| 维度 | agentic.nvim | 我们的方案 |
|---|---|---|
| 通信方式 | ACP 协议（stdio JSON-RPC） | 目前是终端 spawn + 文本交互 |
| UI 形态 | 侧边栏多 buffer widget | 浮动终端 + 任务系统 |
| 多 agent | 不支持 | 设计中（task dispatch） |
| session 管理 | tab page 绑定 | nvim pid 绑定 |
| 代码复用 | 协议层可直接搬 | UI 层差异大 |

## 关键发现

1. ACP 协议本身很简单：initialize -> session/new -> session/prompt -> 监听 session/update 通知
2. 复杂度在各 CLI 的消息格式差异，每个 adapter 都有大量特殊处理
3. `claude-agent-acp` 是独立 binary，不是 `claude` CLI 的参数模式
4. 没有多 agent 编排能力，这是我们方案的差异化点
5. 会话持久化用 JSON 文件存 `~/.cache/nvim/agentic/sessions/`，按项目目录分文件夹
