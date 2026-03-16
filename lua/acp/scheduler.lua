--- main 队列 + agent prompt 调度 + 兜底回复
local LOG_DIR = vim.fn.stdpath("config") .. "/logs"
local LOG_FILE = LOG_DIR .. "/acp-bus.log"

local function log(level, msg)
	vim.fn.mkdir(LOG_DIR, "p")
	local f = io.open(LOG_FILE, "a")
	if not f then return end
	f:write(string.format("%s [%s] scheduler: %s\n", os.date("%H:%M:%S"), level, msg))
	f:close()
end

local Scheduler = {}
Scheduler.__index = Scheduler

local MAX_MAIN_QUEUE = 10

--- @param bus table Bus 实例
function Scheduler.new(bus)
	return setmetatable({
		bus = bus,
		_main_busy = false,
		_main_queue = {},
		_drain_pending = false,
	}, Scheduler)
end

--- 推送消息给主 agent client（串行队列，防并发）
--- @param content string 消息内容
--- @param from? string 发送者名称
function Scheduler:push_to_main(content, from)
	local bus = self.bus
	local main = bus.agents["main"]
	if not main or not main.client then
		log("WARN", "push_to_main: main client is nil")
		bus:post("系统", "⚠ main 未连接，消息未送达: " .. content:sub(1, 60), { no_route = true })
		return
	end
	if not main.client.alive then
		log("WARN", "push_to_main: main client not alive")
		main.status = "disconnected"
		bus:state_changed()
		bus:post("系统", "⚠ main 已离线，消息未送达: " .. content:sub(1, 60), { no_route = true })
		return
	end

	-- 如果 main Chat 正在直接对话，入队等待
	local main_chat = bus:find_main_chat()
	if main_chat and main_chat.streaming then
		log("INFO", "push_to_main: main chat busy, queueing  msg=" .. content:sub(1, 80))
		self:_enqueue_main(content, from)
		self:_schedule_drain()
		return
	end

	-- 队列：如果正在处理，入队等待
	if self._main_busy then
		log("INFO", "push_to_main: queued  msg=" .. content:sub(1, 80))
		self:_enqueue_main(content, from)
		return
	end
	self._main_busy = true
	main.status = "streaming"
	-- 同步主 Chat 的 streaming 状态
	if main_chat then
		main_chat.streaming = true
		main_chat:_refresh_winbar()
	end
	bus:state_changed()

	local t0 = os.clock()
	log("INFO", "push_to_main: start  msg=" .. content:sub(1, 80))

	-- 在主 chat buffer 里标记频道来源
	bus:notify_main_chat(from or "频道", content)

	local stream_buf = ""

	-- 用 on_chunk（第3参数）收集输出，不再 monkey-patch on_update
	main.client:prompt(content, function(_)
		local elapsed = math.floor((os.clock() - t0) * 1000)
		log("INFO", "push_to_main: done  elapsed=" .. elapsed .. "ms  reply_len=" .. #stream_buf)
		if stream_buf ~= "" then
			vim.schedule(function()
				bus:post("main", stream_buf)
			end)
		end
		-- 处理队列里的下一条
		self._main_busy = false
		main.status = "idle"
		-- 同步主 Chat 的 streaming 状态
		if main_chat then
			main_chat.streaming = false
			main_chat:_refresh_winbar()
		end
		bus:state_changed()
		if #self._main_queue > 0 then
			local next_item = table.remove(self._main_queue, 1)
			vim.schedule(function()
				self:push_to_main(next_item.content, next_item.from)
			end)
		end
	end, function(params)
		-- on_chunk：只收集 text，不影响全局 on_update
		if not params or not params.update then return end
		local kind = params.update.sessionUpdate
		if kind == "agent_message_chunk" then
			local text = bus:_extract_text(params.update.content)
			if text ~= "" then stream_buf = stream_buf .. text end
		end
	end)
end

--- 入队 main 消息（带背压）
function Scheduler:_enqueue_main(content, from)
	if #self._main_queue >= MAX_MAIN_QUEUE then
		log("WARN", "push_to_main: queue full, dropping  msg=" .. content:sub(1, 80))
		self.bus:post("系统", "⚠ main 队列已满（" .. MAX_MAIN_QUEUE .. "），消息被丢弃", { no_route = true })
		return
	end
	self._main_queue[#self._main_queue + 1] = { content = content, from = from }
	self.bus:state_changed()
end

--- 延迟检查队列（等 main chat 空闲后排水）
function Scheduler:_schedule_drain()
	if self._drain_pending then return end
	self._drain_pending = true
	vim.defer_fn(function()
		self._drain_pending = false
		if self._main_busy or #self._main_queue == 0 then return end
		local main_chat = self.bus:find_main_chat()
		if main_chat and main_chat.streaming then
			self:_schedule_drain() -- 还在忙，继续等
			return
		end
		local next_item = table.remove(self._main_queue, 1)
		self:push_to_main(next_item.content, next_item.from)
	end, 500)
end

--- 推送消息给指定 agent
--- @param name string 目标 agent
--- @param text string 消息内容
--- @param sender? string 发送者名称
function Scheduler:push_to_agent(name, text, sender)
	local bus = self.bus
	local agent = bus.agents[name]
	if not agent or not agent.client or not agent.client.alive then
		log("WARN", "push_to_agent  name=" .. name .. "  not alive")
		bus:post("系统", name .. " 不在线")
		return
	end
	log("INFO", "push_to_agent  name=" .. name
		.. "  sender=" .. tostring(sender)
		.. "  text_len=" .. #text
		.. "  first_prompt=" .. tostring(not agent.prompted))
	-- 第一次发消息时，把 system prompt 前置
	local payload = text
	if not agent.prompted and agent.system_prompt then
		payload = agent.system_prompt .. "\n\n" .. text
		agent.prompted = true
	end
	agent.streaming = true
	agent.status = "streaming"
	agent.stream_buf = ""
	agent.activity = "receiving"
	-- 同步 Chat 的 streaming 状态
	agent:sync_chat_streaming(true)
	bus:state_changed()
	bus:post("系统", "→ " .. name, { no_route = true })
	-- 把 user 消息写入 agent chat buffer
	if agent.chat then
		agent.chat:_append_role("You", text)
	end
	-- 写入 agent 日志：user 消息
	bus:session_write("agent-" .. name .. ".log",
		string.format("[%s] [You]  %s\n\n", os.date("%H:%M:%S"), text))
	local prompt_time = os.time()
	agent.client:prompt(payload, function(stop_reason, err)
		vim.schedule(function()
			agent.streaming = false
			agent.status = "idle"
			agent.activity = nil
			-- 同步 Chat 的 streaming 状态
			agent:sync_chat_streaming(false)
			bus:state_changed()
			log("INFO", "push_to_agent done  name=" .. name
				.. "  stop=" .. tostring(stop_reason)
				.. "  reply_len=" .. #(agent.stream_buf or ""))
			-- 写入 agent 日志：assistant 回复
			if agent.stream_buf and agent.stream_buf ~= "" then
				bus:session_write("agent-" .. name .. ".log",
					string.format("[%s] [%s]  %s\n\n", os.date("%H:%M:%S"), name, agent.stream_buf))
			end
			-- 兜底：检测 agent 是否在本次 prompt 期间自行回复了频道
			if not stop_reason or (stop_reason ~= "cancelled" and stop_reason ~= "error") then
				local self_posted = false
				for i = #bus.messages, 1, -1 do
					local msg = bus.messages[i]
					if msg.timestamp < prompt_time then break end
					if msg.from == name then
						self_posted = true
						break
					end
				end
				if not self_posted then
					bus:post(name, "@main 已完成（未主动回复）")
				end
			end
			agent.stream_buf = ""
			if stop_reason == "cancelled" then
				bus:post("系统", name .. " 已取消")
			elseif stop_reason == "error" then
				log("ERROR", "push_to_agent error  name=" .. name
					.. "  " .. tostring(err and err.message or "unknown"))
				local detail = ""
				if err then
					detail = " (" .. tostring(err.code or "") .. " " .. tostring(err.message or ""):sub(1, 80) .. ")"
				end
				local err_msg = name .. " 执行出错" .. detail
				bus:post("系统", err_msg)
				-- 通知发送者（通过 post 走正常路由）
				if sender and sender ~= "系统" and bus.agents[sender] then
					bus:post("系统", "@" .. sender .. " " .. err_msg)
				end
			end
		end)
	end)
end

--- 从 agent 输出中提取摘要（用于兜底回复）
--- @param text string 完整输出
--- @param max_len number 最大字符数
--- @return string
function Scheduler:_extract_summary(text, max_len)
	max_len = max_len or 200
	text = vim.trim(text)
	if text == "" then return "（已完成）" end
	if #text <= max_len then return text end
	-- 取最后一段（通常是结论）
	local last_para = text:match("\n\n([^\n].+)$")
	if last_para and #last_para <= max_len then
		return last_para
	end
	return text:sub(1, max_len - 1) .. "…"
end

--- 获取 main 队列深度（供 winbar 使用）
function Scheduler:main_queue_depth()
	return #self._main_queue
end

return Scheduler
