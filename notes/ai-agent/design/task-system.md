# AI Agent Task System

## 架构概览

子 AI 通过文件通信，nvim 用 fs_event 监听，汇总后通知主 AI。

```
~/.ai-tasks/{nvim-pid}/
├── task-xxx/
│   ├── task.md      ← 主 AI 写：任务描述
│   ├── status       ← 单词：pending → running → done / error
│   └── result.md    ← 子 AI 写：执行结果
```

## 文件职责

| 文件 | 职责 |
|------|------|
| `lua/core/agent_api.lua` | RPC API 入口，所有函数 pcall+wrap 返回 JSON `{ok, data/error}` |
| `lua/core/task_watcher.lua` | `uv.new_fs_event()` 监听 status 文件，done/error 时 vim.notify |
| `lua/core/init.lua` | setup 里加载 task_watcher |

## agent_api.lua 函数清单

### 原有
- `open_file` / `get_context` / `get_buffers` / `get_diagnostics` / `exec_lua` / `notify`
- `spawn_cli({cmd, mode?, name?})` — 开终端跑子 AI
- `send_to_terminal({name?, bufnr?, text})` — 往终端发文字
- `get_terminal_output({name?, bufnr?, tail?})` — 读终端输出
- `list_terminals()` — 列出所有 spawned 终端

### 新增（task 系统）
- `create_task({name, description, work_dir?})` — 建目录写 task.md + status，自动注册 watcher
- `assign_task({agent_name, task_name})` — 读 task.md 拼指令发给子 AI 终端，status→running
- `list_tasks()` — 扫描所有任务返回 [{name, status, has_result, created_at}]
- `get_task_result({name})` — 读 result.md 返回干净文本

### 内部暴露
- `_spawned_terminals` — 终端状态表，task_watcher 用
- `_task_base_dir` — `~/.ai-tasks/{pid}`

## task_watcher.lua 机制

- `watch_task(name)` — 对单个 status 文件启 fs_event
- status 变 done/error → `vim.schedule` 读文件 → `build_summary()` → `vim.notify()`
- `stop_all()` — 关闭所有 watcher handle
- VimLeavePre autocmd → `stop_all()` + `rm -rf ~/.ai-tasks/{pid}/`

## assign_task 发给子 AI 的指令格式

```
你的任务在 ~/.ai-tasks/{pid}/{name}/task.md
请阅读任务描述并执行。

任务内容：
{task.md 内容}

完成规则：
1. 把执行结果写到 ~/.ai-tasks/{pid}/{name}/result.md
2. 把 ~/.ai-tasks/{pid}/{name}/status 文件内容改为 done
3. 如果出错，把 status 改为 error，result.md 里写错误说明
```

## 通知格式

```
[AI-TASKS] 2/3 completed
  review (agent_name): done → ~/.ai-tasks/{pid}/review/result.md
  test (agent_name): done → ~/.ai-tasks/{pid}/test/result.md
  refactor (agent_name): running
```

## 日志

task 系统的调试日志写到 `~/.ai-tasks/{pid}/debug.log`，格式：
```
timestamp [level] source: message
```

## 已知限制 / TODO

- [ ] 通知目前用 vim.notify，未来要能注入到主 AI 终端
- [x] ~~build_summary 里 agent 名匹配是粗糙的（取第一个终端名）~~ → 仍粗糙，需要 task→agent 映射
- [ ] 无任务依赖编排
- [ ] 无冲突检测
- [ ] 无 messages.jsonl 管道（先用 status + result.md）
- [ ] 考虑迁移到 --sdk-url WebSocket 方案，见 [research/sdk-url-protocol.md](../research/sdk-url-protocol.md)

## 迭代日志

详细一手记录在 `~/.claude/skills/ai-task-dispatch/CHANGELOG.md`

### 2026-03-08: v1 初始实现
- 4 个 task API 函数 + task_watcher fs_event 监听
- 文件通信：task.md / status / result.md
- VimLeavePre 清理

### 2026-03-08: 首次实测修复
- spawn_cli 改用 `zsh -ic` 包裹 cmd，让 alias（c1/c2）生效
- assign_task 末尾 `\n` → `\r`，修复 Claude CLI 不提交的问题
- list_tasks / build_summary 跳过非目录项，修复 debug.log 被当任务扫描
- cleanup 改为归档到 `~/.ai-tasks/archive/` 而非删除
- 子 Claude 需要 `--dangerously-skip-permissions` 启动
