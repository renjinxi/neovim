--- Chat/频道输入框命令系统
--- / 开头的输入走命令分发，其余走正常消息

local M = {}

local function next_agent_name(channel, adapter)
	local used = {}
	for name in pairs(channel.agents or {}) do
		used[name] = true
	end
	local i = 1
	while used[adapter .. "-" .. i] do
		i = i + 1
	end
	return adapter .. "-" .. i
end

--- 解析命令："/compact foo bar" → "compact", "foo bar"
--- @param text string
--- @return string|nil cmd
--- @return string args
function M.parse(text)
	return text:match("^/(%S+)%s*(.*)")
end

-- ============================================================================
-- Chat 级命令（作用于单个 Chat 实例的 client）
-- ============================================================================

local chat_commands = {}

chat_commands.status = function(chat)
	local lines = {}
	lines[#lines + 1] = "adapter: " .. (chat.adapter_name or "?")
	lines[#lines + 1] = "display: " .. (chat.display_name or chat.adapter_name or "?")
	if chat.client then
		lines[#lines + 1] = "alive: " .. tostring(chat.client.alive)
		lines[#lines + 1] = "session: " .. tostring(chat.client.session_id)
		lines[#lines + 1] = "pid: " .. tostring(chat.client.pid)
	else
		lines[#lines + 1] = "client: nil"
	end
	lines[#lines + 1] = "streaming: " .. tostring(chat.streaming)
	chat:_append_system(table.concat(lines, "\n"))
end

chat_commands.cancel = function(chat)
	chat:cancel()
end

chat_commands.exit = function(chat)
	chat:stop()
	chat:_append_system("已退出")
end

chat_commands.compact = function(chat)
	if not chat.client or not chat.client.alive then
		chat:_append_system("client 未连接")
		return
	end
	chat:_append_system("/compact 暂未接通原生 CLI 命令，当前实现已禁用")
end

chat_commands.leave = function(chat)
	if not chat.display_name then
		chat:_append_system("不在频道中")
		return
	end
	local acp = require("acp")
	local ok, err = acp.bus_leave(chat.display_name)
	if ok then
		chat:_append_system("已退出频道")
	else
		chat:_append_system("退出失败: " .. tostring(err))
	end
end

--- 执行 Chat 级命令
--- @param chat table Chat 实例
--- @param text string 原始输入（含 /）
--- @return boolean handled
function M.handle_chat(chat, text)
	local cmd, _ = M.parse(text)
	if not cmd then return false end
	local handler = chat_commands[cmd]
	if handler then
		handler(chat)
		return true
	end
	chat:_append_system("未知命令: /" .. cmd)
	return true
end

-- ============================================================================
-- 频道级命令（作用于 Channel）
-- ============================================================================

local channel_commands = {}

channel_commands.add = function(channel, args)
	local parts = vim.split(vim.trim(args), "%s+")
	local adapter = parts[1]
	if not adapter or adapter == "" then
		channel:post("系统", "/add <adapter> [name]", { no_route = true })
		return
	end
	local name = parts[2]
	if not name or name == "" then
		name = next_agent_name(channel, adapter)
	end
	channel:add_agent(name, adapter)
end

channel_commands.stop = function(channel, args)
	local name = vim.trim(args)
	if name == "" then
		channel:post("系统", "/stop <agent_name>", { no_route = true })
		return
	end
	local acp = require("acp")
	local ok, err = acp.bus_leave(name)
	if not ok then
		channel:post("系统", "停止失败: " .. tostring(err), { no_route = true })
	end
end

channel_commands.list = function(channel)
	local agents = channel:list_agents()
	if #agents == 0 then
		channel:post("系统", "无 agent", { no_route = true })
		return
	end
	local lines = {}
	for _, a in ipairs(agents) do
		lines[#lines + 1] = string.format("  %s  [%s]  %s", a.name, a.kind, a.status)
	end
	channel:post("系统", table.concat(lines, "\n"), { no_route = true })
end

channel_commands.open = function(channel, args, view)
	local name = vim.trim(args)
	if name == "" then
		channel:post("系统", "/open <agent_name>", { no_route = true })
		return
	end
	if view then
		view:open_agent_buf(name)
	end
end

channel_commands.pick = function(channel)
	if not channel then
		return
	end
	require("acp.picker").open()
end

--- 执行频道级命令
--- @param channel table Channel 实例
--- @param text string 原始输入（含 /）
--- @param view? table ChannelView 实例（/open 需要）
--- @return boolean handled
function M.handle_channel(channel, text, view)
	local cmd, args = M.parse(text)
	if not cmd then return false end
	local handler = channel_commands[cmd]
	if handler then
		handler(channel, args or "", view)
		return true
	end
	-- 未知命令：拦截并提示，避免当普通消息发出
	local known = {}
	for k in pairs(channel_commands) do
		known[#known + 1] = "/" .. k
	end
	table.sort(known)
	channel:post("系统", "未知命令: /" .. cmd .. "。可用: " .. table.concat(known, " "), { no_route = true })
	return true
end

return M
