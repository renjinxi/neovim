# #31 子 Agent 回复兜底方案

claude1 | 2026-03-16

---

## 问题

子 agent 完成 prompt 后应通过 bash 工具调 nvim RPC 发消息到频道，但经常忘记。频道里看不到回复，main 不知道 agent 做完了什么。

当前兜底（L583）`self:post(name, "@main 已完成")` 问题：每次都发、内容为空、重复路由。

## 方案：三层防线

### 第一层：优化 system prompt（降低忘回复概率）

当前 prompt 的回复命令淹没在规则列表里，不够醒目。改为：

```lua
function M.get_bus_system_prompt(agent_name, channel_id)
    local sock = vim.env.NVIM_LISTEN_ADDRESS or vim.v.servername
    local tmpfile = "/tmp/acp_msg_" .. agent_name .. ".txt"
    local notes_dir = "notes/acp-bus/" .. (channel_id or "default")
    return string.format(
        [[你是 %s，在一个多 agent 协作频道里。

⚠️ 关键要求：完成任务后必须回复频道。不回复 = 任务未完成。

回复命令（直接复制修改内容即可）：
echo '@main 你的回复内容' > '%s' && nvim --server '%s' --remote-expr 'luaeval("require(\"acp.rpc\").bus_post_file(\"%s\",\"%s\")")'

频道规则：
- @收件人 开头，默认 @main
- 频道消息 50 字以内，只写结论
- 长内容写文件到 %s/，频道附路径]],
        agent_name,
        tmpfile,
        sock,
        agent_name,
        tmpfile,
        notes_dir
    )
end
```

变化：
1. `⚠️ 关键要求` 置顶强调
2. 回复命令前有明确标注"直接复制修改"
3. 删掉"每个任务回复一次，然后等指令"（冗余）

### 第二层：检测 agent 是否自行回复（核心改动）

在 `send_to_agent` 的 prompt 回调里，检查 agent 在本次 prompt 期间是否已经 post 过频道消息。如果没有，触发兜底。

```lua
-- send_to_agent 里，prompt 前记录时间
local prompt_time = os.time()

-- prompt callback 里
agent.client:prompt(payload, function(stop_reason, err)
    vim.schedule(function()
        ...existing status reset...

        -- 检测 agent 是否在本次 prompt 期间自行回复了频道
        local self_posted = false
        for i = #self.messages, 1, -1 do
            local msg = self.messages[i]
            if msg.timestamp < prompt_time then break end
            if msg.from == name then
                self_posted = true
                break
            end
        end

        -- 兜底：agent 没自行回复，且有输出内容
        if not self_posted then
            if agent.stream_buf and agent.stream_buf ~= "" then
                local summary = self:_extract_summary(agent.stream_buf, 200)
                self:post(name, "@main " .. summary)
            else
                self:post("系统", name .. " 已完成（无输出）", { no_route = true })
            end
        end

        -- 删掉旧的无条件 "@main 已完成"
        agent.stream_buf = ""
        ...existing error/cancel handling...
    end)
end)
```

### 第三层：智能摘要提取

新增 `_extract_summary` 方法，从 stream_buf 提取有意义的摘要：

```lua
--- 从 agent 输出中提取摘要（用于兜底回复）
--- @param text string 完整输出
--- @param max_len number 最大字符数
--- @return string
function Bus:_extract_summary(text, max_len)
    max_len = max_len or 200
    -- 去掉前后空白
    text = vim.trim(text)
    if text == "" then return "（已完成）" end

    -- 如果整体够短，直接用
    if #text <= max_len then return text end

    -- 取最后一段（通常是结论）
    local last_para = text:match("\n\n([^\n].+)$")
    if last_para and #last_para <= max_len then
        return last_para
    end

    -- 都太长，截断
    return text:sub(1, max_len - 1) .. "…"
end
```

策略：优先取最后一段（agent 通常把结论放最后），退而截断。

---

## 改动汇总

| 文件 | 改动 | 行数 |
|------|------|------|
| adapter.lua `get_bus_system_prompt` | 优化 prompt 措辞 | ~5 行改 |
| bus.lua `send_to_agent` | 加 prompt_time 记录 + self_posted 检测 + 兜底 | ~15 行 |
| bus.lua `send_to_agent` | 删除旧的无条件 `@main 已完成` (L583-584) | -2 行 |
| bus.lua 新增 `_extract_summary` | 摘要提取 | ~15 行 |
| **共计** | | ~35 行 |

## 行为对比

| 场景 | 旧行为 | 新行为 |
|------|--------|--------|
| agent 自行回复 | 回复 + 多余的"已完成" | 回复（无多余消息）|
| agent 忘记回复，有输出 | 只有"已完成" | 自动提取摘要 post |
| agent 忘记回复，无输出 | 只有"已完成" | 系统提示"已完成（无输出）" |
| agent 出错 | 错误消息 | 错误消息（不变）|
| agent 被取消 | "已取消" | "已取消"（不变）|

## 注意点

1. `self_posted` 检测依赖 `msg.from == name`。agent 通过 RPC 发消息时 from 是 agent_name，匹配没问题。
2. `_extract_summary` 的"取最后一段"在 agent 输出是 markdown 时效果最好（段落用空行分隔）。
3. 兜底发出的消息含 `@main`，会触发路由。这是期望行为——main 需要知道结果。
