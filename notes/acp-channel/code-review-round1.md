# Code Review Round 1 — codex1 代码变更

## 1. lua/acp/chat.lua — _append_system 换行修复 + stop()/close() 拆分

### _append_system 换行修复
**正确**。原来 `"*" .. text .. "*"` 对多行文本会产生错误的 markdown 斜体（只有首尾行有 `*`）。新实现逐行 split 后首行加 `*`、末行加 `*`，正确处理了多行情况。

**边界问题**：单行时 `lines[1]` 和 `lines[#lines]` 是同一个元素，结果是 `*text*`，正确。空字符串 `""` 会变成 `**`（markdown 粗体空文本），但 `_append_system` 调用方都传非空字符串，实际无影响。

### stop()/close() 拆分
**正确且必要**。`bus_leave` 需要停进程但不关窗口/buffer，拆分出 `stop()` 恰好满足。`close()` 调用 `self:stop()` 再清理 UI 资源，逻辑清晰，无遗漏。

`stop()` 中 `self.streaming = false` + `self.stream_started = false` + `_refresh_winbar()` 是正确的状态重置。

## 2. lua/acp/channel.lua — remove_agent + post() 长消息文件化

### remove_agent
**正确**。设 `agent.leaving = true` 后立即从 `self.agents` 中移除，配合 scheduler 的 `agent.leaving` 检查可以防止回调执行时 agent 已不存在的问题。

**注意**：`remove_agent` 返回 agent 对象但不负责停止进程——这个职责正确地留给了调用方 `init.lua:bus_leave()`。

### post() 长消息文件化
**基本正确**，几个边界问题：

1. **路径是相对路径** `notes/acp-bus/...`——依赖 cwd 与 nvim config 目录一致。当前 ACP 的使用场景下 cwd 通常是项目目录而非 config 目录，**这个文件会写到项目目录下而非 config 目录**。建议用 `vim.fn.stdpath("config") .. "/notes/..."` 或 `self.cwd .. "/notes/..."` 明确路径。
2. **`#content > 300` 按字节计**——中文 UTF-8 每字约 3 字节，300 字节约等于 100 个中文字符。这个阈值可能偏低，实际效果取决于使用场景。不是 bug，但值得留意。
3. **`content:sub(1, 50)` 截断也按字节**——中文可能在 UTF-8 多字节序列中间截断，产生乱码。建议用 `vim.fn.strcharpart(content, 0, 50)` 或 `vim.str_byteindex()` 做安全截断。
4. **`from:gsub("[^%w_%-]", "")` 对中文发送者名**——如 "系统" 会被清空变成 `.md`。`from` 是中文时 filename 变成 `174441-.md`，不会报错但文件名丑。

### on_exit_notify 小重构
**等价变换**，从 `if self.agents[name] then ... end; self:post(...)` 变成 `if not ... then return end; ...; self:post(...)`。语义一致，guard clause 更清晰。但注意：原版 `self:post()` 在 agent 不存在时也会执行（报退出），新版 agent 不存在时直接 return 不发消息。**这可能是有意为之**——agent 被 remove 后不再报退出消息，合理。

## 3. lua/acp/channel_view.lua — markdown 渲染

### format_gap
**正确**，逻辑清晰。< 2 秒不显示，≥60 秒显示分+秒，中间显示秒。

### looks_like_code
**功能性可用**，启发式检测代码内容。几个问题：

1. **第一个检查 `content:find("```")` 返回 false**——意思是"已有代码块标记就不包装"，合理。
2. **`content:find("\t")` 返回 true**——tab 就认定是代码，对于普通文本中带 tab 的情况会误判，但频道消息场景下可接受。
3. **`content:find("^%s*```")` 返回 true**——这和第 1 个检查矛盾：如果内容以 ``` 开头，第 1 个检查会先返回 false（不会到这里）。**这行永远不会被执行到**，是死代码。

### render_markdown_content
**注意**：`vim.list_extend` 是原地修改第一个参数的。`vim.list_extend(lines, { "```" })` 会修改原 `lines`。`vim.list_extend({ "```" }, modified_lines)` 结果正确，但要注意 `lines` 已被修改（多了尾部 ```）。最终结果正确：`{ "```", ...original_lines..., "```" }`。

### _render_message markdown 化
**大幅改进了可读性**。从原来的纯文本 `[HH:MM:SS] [from]  content` 改为 markdown 格式 `## from` + 时间元数据 + 内容。

分割线 `---` 在 `count > 2` 时添加，首条消息不加，合理。

## 4. lua/acp/init.lua — :Acp leave + bus_leave + open_chat --join 重构

### :Acp leave 命令
**正确**。补全支持也加了（`parts[2] == "leave"` 与 cli 共用 agent 名列表），一致。

### bus_leave
**正确**。流程：remove_agent → 拿到 agent → stop chat/client。优先用 `agent.chat:stop()`（会清理 streaming 状态），fallback 到 `agent.client:stop()`。`agent.chat.stop` 检查是用来防御无 stop 方法的情况，实际上 Chat 类始终有 stop，但防御编程无害。

### open_chat --join 重构
**正确**。拆分了 join/非 join 两条路径：
- `--join`：**强制**覆盖 main agent 的 client，即使已有活跃连接
- 默认：只在 main 无活跃 client 时自动注册

**注意**：`opts.join = nil` 在传给 `r:create_chat()` 前删除，正确，避免 join 字段污染 chat 构造。

`chat_args` 的过滤逻辑：过滤掉 "chat" 和 "--join"，剩下的取 [1] 作 adapter、[2] 作 api_num。**有一个微妙 bug**：如果用户输入 `:Acp chat --join claude 2`，`args` 是 `{"chat", "--join", "claude", "2"}`，过滤后 `chat_args` 是 `{"claude", "2"}`，正确。但如果输入 `:Acp chat claude --join 2`，过滤后是 `{"claude", "2"}`，也正确。**但如果输入 `:Acp chat claude 2 --join`**，过滤后是 `{"claude", "2"}`，也正确。所以无论 `--join` 位置如何都能正确解析。

## 5. lua/acp/rpc.lua — bus_leave RPC 接口

**正确且标准**。参数校验 → 调用 acp.bus_leave → 返回 ok/err。与其他 RPC 函数风格一致。

## 6. lua/acp/scheduler.lua — agent.leaving 防护 + idle 系统通知

### agent.leaving 防护
**关键修复**。`push_to_agent` 的 prompt 回调是异步的，如果在 prompt 执行期间调用了 `remove_agent`（设 `leaving = true`），回调触发时 agent 已从 `bus.agents` 中删除。没有这个 guard，后续代码会尝试修改已删除 agent 的状态、发消息到频道，可能触发异常或逻辑混乱。

**但有一个问题**：`agent.leaving` check 后直接 return，意味着不会执行 `agent.streaming = false` 等清理。由于 agent 已被 remove 且 chat 已 stop，这些状态不再有意义，所以 return 是安全的。但 `stream_buf` 不会被清空，如果 agent 对象被外部持有会有内存泄漏。**实际上 remove_agent 后无人持有 agent 引用，GC 会回收，无问题。**

### idle 系统通知
**合理新增**。`bus:post("系统", name .. " 已完成", { no_route = true })` 在非取消/非错误的正常完成后发一条系统通知，让频道用户看到 agent 状态变化。`{ no_route = true }` 避免触发路由递归，正确。

---

## 总结

| 文件 | 评级 | 关键问题 |
|------|------|----------|
| chat.lua | ✅ 无问题 | — |
| channel.lua | ⚠️ 需注意 | post() 路径是相对路径，UTF-8 截断可能乱码 |
| channel_view.lua | ⚠️ 小问题 | looks_like_code 有一行死代码 |
| init.lua | ✅ 无问题 | — |
| rpc.lua | ✅ 无问题 | — |
| scheduler.lua | ✅ 无问题 | — |

**需要修的**：
1. `channel.lua:post()` 的 `content:sub(1, 50)` UTF-8 截断问题——用 `vim.fn.strcharpart` 替代
2. `channel.lua:post()` 的相对路径问题——考虑是否需要绝对路径

**可选清理**：
3. `channel_view.lua:looks_like_code()` 第 3 行检查是死代码，可删除
