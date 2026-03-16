--- 频道 Buffer：多 agent 消息展示
local adapter_mod = require("acp.adapter")

local LOG_DIR = vim.fn.stdpath("config") .. "/logs"
local LOG_FILE = LOG_DIR .. "/acp-bus.log"

local function log(level, msg)
	vim.fn.mkdir(LOG_DIR, "p")
	local f = io.open(LOG_FILE, "a")
	if not f then
		return
	end
	f:write(string.format("%s [%s] bus: %s\n", os.date("%H:%M:%S"), level, msg))
	f:close()
end

--- 追加内容到频道会话日志文件
local function session_write(session_dir, filename, content)
	if not session_dir then return end
	local f = io.open(session_dir .. "/" .. filename, "a")
	if not f then return end
	f:write(content)
	f:close()
end

local Bus = {}
Bus.__index = Bus

function Bus.new()
	local channel_id = os.date("%Y%m%d-%H%M%S")
	return setmetatable({
		channel_id = channel_id,
		cwd = vim.fn.getcwd(),
		messages = {}, -- [{from, content, timestamp}]
		agents = {}, -- {name -> {kind, client, status, streaming, adapter_name, ...}}
		buf = nil,
		win = nil,
		input_buf = nil,
		input_win = nil,
		_main_busy = false,
		_main_queue = {},
		_drain_pending = false,
		_saved = false,
		session_dir = nil, -- 本次频道的日志目录
	}, Bus)
end

--- 打开频道 buffer
function Bus:open()
	-- 主 buffer
	self.buf = vim.api.nvim_create_buf(false, true)
	vim.bo[self.buf].buftype = "nofile"
	vim.bo[self.buf].bufhidden = "hide"
	vim.bo[self.buf].swapfile = false
	vim.bo[self.buf].filetype = "markdown"
	pcall(vim.api.nvim_buf_set_name, self.buf, "acp://bus/" .. os.time())

	-- 初始化本次频道的日志目录
	self.session_dir = LOG_DIR .. "/bus-" .. self.channel_id
	vim.fn.mkdir(self.session_dir, "p")
	session_write(self.session_dir, "channel.log", "# 频道会话 " .. self.channel_id .. "\n\n")

	-- 输入 buffer
	self.input_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[self.input_buf].buftype = "nofile"
	vim.bo[self.input_buf].bufhidden = "hide"
	vim.bo[self.input_buf].swapfile = false

	-- 布局
	local width = math.floor(vim.o.columns * 0.4)
	vim.cmd("botright " .. width .. "vsplit")
	self.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(self.win, self.buf)
	vim.wo[self.win].number = false
	vim.wo[self.win].relativenumber = false
	vim.wo[self.win].signcolumn = "no"
	vim.wo[self.win].wrap = true
	vim.wo[self.win].linebreak = true

	vim.cmd("belowright 3split")
	self.input_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(self.input_win, self.input_buf)
	vim.wo[self.input_win].winfixheight = true
	vim.wo[self.input_win].number = false
	vim.wo[self.input_win].relativenumber = false
	vim.wo[self.input_win].signcolumn = "no"

	-- 输入框动态高度
	self:_setup_input_autoresize()

	-- 欢迎
	vim.bo[self.buf].modifiable = true
	vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, { "# 频道", "" })
	vim.bo[self.buf].modifiable = false

	-- keymaps：q 只关窗口，不杀进程
	vim.keymap.set({ "n", "i" }, "<CR>", function()
		self:_submit_input()
	end, { buffer = self.input_buf, noremap = true, silent = true })

	vim.keymap.set("n", "q", function()
		self:hide()
	end, { buffer = self.buf, noremap = true, silent = true })

	vim.keymap.set("n", "q", function()
		self:hide()
	end, { buffer = self.input_buf, noremap = true, silent = true })

	-- BufWipeout 保护：buffer 被强制关闭时清理进程
	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = self.buf,
		once = true,
		callback = function()
			self:_cleanup_agents()
		end,
	})

	-- VimLeavePre：nvim 退出时保存快照 + 清理进程
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = vim.api.nvim_create_augroup("acp_bus_cleanup", { clear = true }),
		once = true,
		callback = function()
			self:save_snapshot()
			self:_cleanup_agents()
		end,
	})

	-- 聚焦输入框
	if self.input_win and vim.api.nvim_win_is_valid(self.input_win) then
		vim.api.nvim_set_current_win(self.input_win)
		vim.cmd("startinsert")
	end

	-- 注册 main agent（kind="local"，client 由外部注入）
	self.agents["main"] = {
		kind = "local",
		client = nil,
		status = "idle",
		adapter_name = "local",
		streaming = false,
	}

	-- 初始刷新 winbar
	self:_refresh_winbar()
end

--- 截断字符串（超出 max 则加 …）
local function truncate(s, max)
	if not s then return "" end
	if #s <= max then return s end
	return s:sub(1, max - 1) .. "…"
end

--- 刷新频道窗口的 winbar（agent 状态栏）
function Bus:_refresh_winbar()
	if not self.win or not vim.api.nvim_win_is_valid(self.win) then return end
	local win_width = vim.api.nvim_win_get_width(self.win)
	local parts = {}
	-- main 排最前
	local names = {}
	for name in pairs(self.agents) do
		names[#names + 1] = name
	end
	table.sort(names, function(a, b)
		if a == "main" then return true end
		if b == "main" then return false end
		return a < b
	end)
	-- 每个标签最大宽度，根据 agent 数量和窗口宽度动态计算
	local max_label = math.max(12, math.floor((win_width - 2) / math.max(1, #names)) - 3)
	max_label = math.min(max_label, 25)

	for _, name in ipairs(names) do
		local agent = self.agents[name]
		local icon, hl, hint
		local status = agent.status or "idle"
		-- 从 client 状态推导
		if agent.client then
			if not agent.client.alive then
				status = "disconnected"
			elseif agent.streaming then
				status = "streaming"
			end
		elseif agent.kind ~= "local" and agent.status ~= "connecting" then
			status = "disconnected"
		end
		if status == "disconnected" or status == "error" then
			icon, hl = "○", "Comment"
		elseif status == "connecting" then
			icon, hl = "◌", "Comment"
		elseif status == "streaming" then
			icon, hl = "●", "DiagnosticOk"
			hint = truncate(agent.activity, 10)
		else
			icon, hl = "◉", "Normal"
		end
		local adapter = agent.adapter_name or "?"
		local base = name == adapter and name or (name .. "/" .. adapter)
		base = truncate(base, max_label - 4) -- 预留 icon + 空格 + hint
		local label = hint and string.format("%s %s [%s]", icon, base, hint) or (icon .. " " .. base)
		-- main 显示队列深度
		if name == "main" and #self._main_queue > 0 then
			label = label .. string.format(" [q:%d]", #self._main_queue)
		end
		parts[#parts + 1] = string.format("%%#%s#%s%%*", hl, label)
	end
	if #parts == 0 then
		vim.wo[self.win].winbar = " 频道"
	else
		vim.wo[self.win].winbar = " " .. table.concat(parts, "  ")
	end
end

--- 输入框动态高度（min 3, max 10）
function Bus:_setup_input_autoresize()
	if not self.input_buf then return end
	local group = vim.api.nvim_create_augroup("acp_bus_autoresize_" .. self.input_buf, { clear = true })
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = group,
		buffer = self.input_buf,
		callback = function()
			if not self.input_win or not vim.api.nvim_win_is_valid(self.input_win) then return end
			local line_count = vim.api.nvim_buf_line_count(self.input_buf)
			local height = math.max(3, math.min(10, line_count))
			vim.api.nvim_win_set_height(self.input_win, height)
		end,
	})
end

--- 只关窗口，保留进程（可以重新打开）
function Bus:hide()
	if self.input_win and vim.api.nvim_win_is_valid(self.input_win) then
		vim.api.nvim_win_close(self.input_win, true)
		self.input_win = nil
	end
	if self.win and vim.api.nvim_win_is_valid(self.win) then
		vim.api.nvim_win_close(self.win, true)
		self.win = nil
	end
end

--- 重新打开已有频道的窗口
function Bus:show()
	if not self.buf or not vim.api.nvim_buf_is_valid(self.buf) then
		return false
	end
	local width = math.floor(vim.o.columns * 0.4)
	vim.cmd("botright " .. width .. "vsplit")
	self.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(self.win, self.buf)
	vim.wo[self.win].number = false
	vim.wo[self.win].relativenumber = false
	vim.wo[self.win].signcolumn = "no"
	vim.wo[self.win].wrap = true
	vim.wo[self.win].linebreak = true

	-- 必须先切到主 buffer 的 win，再 split 输入框，保证成对
	vim.api.nvim_set_current_win(self.win)
	vim.cmd("belowright 3split")
	self.input_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(self.input_win, self.input_buf)
	vim.wo[self.input_win].winfixheight = true
	vim.wo[self.input_win].number = false
	vim.wo[self.input_win].relativenumber = false
	vim.wo[self.input_win].signcolumn = "no"

	self:_refresh_winbar()
	self:_setup_input_autoresize()

	vim.api.nvim_set_current_win(self.input_win)
	vim.cmd("startinsert")
	return true
end

--- 清理所有 agent 进程和 buffer
function Bus:_cleanup_agents()
	for _, agent in pairs(self.agents) do
		if agent.chat then
			pcall(function() agent.chat:close() end)
		elseif agent.client then
			pcall(function() agent.client:stop() end)
		end
	end
end

--- 添加 agent 到频道
--- @param name string agent 名称
--- @param adapter_name string "claude" | "c1" | "c2" | "gemini"
--- @param opts? table {api_num?, cwd?}
function Bus:add_agent(name, adapter_name, opts)
	log("INFO", "add_agent  name=" .. name .. "  adapter=" .. adapter_name)
	if self.agents[name] and self.agents[name].kind ~= "local" then
		self:post("系统", name .. " 已存在，先 stop 再重新添加")
		return
	end
	opts = opts or {}
	local chat_mod = require("acp.chat")

	local chat_opts = vim.tbl_extend("force", opts, {
		bus_mode = true,
		agent_name = name,
		channel_id = self.channel_id,
	})

	local adapter_config = adapter_mod.get(adapter_name, chat_opts)

	local chat = chat_mod.new(adapter_name, chat_opts)
	chat.bus = self
	chat.bus_agent_name = name

	-- 先注册 agent（client 在 on_ready 里填充）
	self.agents[name] = {
		kind = "spawned",
		client = nil,
		chat = chat,
		status = "connecting",
		adapter_name = adapter_name,
		streaming = false,
		stream_buf = "",
		system_prompt = adapter_config.system_prompt,
		prompted = false,
		chat_buf = nil, -- open_headless 后设置
	}

	chat.on_ready = function(client)
		log("INFO", "add_agent ready  name=" .. name
			.. "  session=" .. tostring(client.session_id))
		local agent = self.agents[name]
		if agent then
			agent.client = client
			agent.status = "idle"
		end
		self:post("系统", name .. " (" .. adapter_name .. ") 已上线")
		self:_refresh_winbar()
	end

	chat:open_headless()
	-- buf 在 open_headless 里同步创建
	self.agents[name].chat_buf = chat.buf
	self:_refresh_winbar()
end

--- 发消息到频道，并按 @mention 路由推送
--- @param from string 发送者
--- @param content string 消息内容
--- @param opts? table {no_route?: bool}
function Bus:post(from, content, opts)
	local msg = {
		from = from,
		content = content,
		timestamp = os.time(),
	}
	self.messages[#self.messages + 1] = msg
	self:_render_message(msg)
	if not (opts and opts.no_route) then
		self:_route(content, from)
	end
end

--- 解析 @mention，推送给被 @ 的 agent（跳过发送者自己）
function Bus:_route(content, from)
	local mentioned = {}
	for name in content:gmatch("@([%w_%-]+)") do
		mentioned[name] = true
	end
	for name in pairs(mentioned) do
		if name ~= from and self.agents[name] then
			log("DEBUG", "_route  from=" .. from .. "  → " .. name)
			self:_send_to(name, content, from)
		end
	end
end

--- 统一消息分发：根据 agent.kind 选择发送方式
function Bus:_send_to(name, content, from)
	local agent = self.agents[name]
	if not agent then return end
	if agent.kind == "local" then
		self:_push_to_main(content, from)
	else
		self:send_to_agent(name, content, from)
	end
end

--- 推送消息给主 agent client，回复完成后 post 到频道（串行队列，防并发）
--- @param content string 消息内容
--- @param from? string 发送者名称
function Bus:_push_to_main(content, from)
	local main = self.agents["main"]
	if not main or not main.client then
		log("WARN", "_push_to_main: main client is nil")
		self:post("系统", "⚠ main 未连接，消息未送达: " .. content:sub(1, 60), { no_route = true })
		return
	end
	if not main.client.alive then
		log("WARN", "_push_to_main: main client not alive")
		main.status = "disconnected"
		self:_refresh_winbar()
		self:post("系统", "⚠ main 已离线，消息未送达: " .. content:sub(1, 60), { no_route = true })
		return
	end

	-- 如果 main Chat 正在直接对话，入队等待
	local main_chat = self:_find_main_chat()
	if main_chat and main_chat.streaming then
		log("INFO", "_push_to_main: main chat busy, queueing  msg=" .. content:sub(1, 80))
		self._main_queue[#self._main_queue + 1] = { content = content, from = from }
		self:_refresh_winbar()
		self:_schedule_main_queue_drain()
		return
	end

	-- 队列：如果正在处理，入队等待
	if self._main_busy then
		log("INFO", "_push_to_main: queued  msg=" .. content:sub(1, 80))
		self._main_queue[#self._main_queue + 1] = { content = content, from = from }
		self:_refresh_winbar()
		return
	end
	self._main_busy = true
	main.status = "streaming"
	-- 同步主 Chat 的 streaming 状态
	if main_chat then
		main_chat.streaming = true
		main_chat:_refresh_winbar()
	end
	self:_refresh_winbar()

	local t0 = os.clock()
	log("INFO", "_push_to_main: start  msg=" .. content:sub(1, 80))

	-- 在主 chat buffer 里标记频道来源
	self:_notify_main_chat(from or "频道", content)

	local stream_buf = ""

	-- 用 on_chunk（第3参数）收集输出，不再 monkey-patch on_update
	main.client:prompt(content, function(_)
		local elapsed = math.floor((os.clock() - t0) * 1000)
		log("INFO", "_push_to_main: done  elapsed=" .. elapsed .. "ms  reply_len=" .. #stream_buf)
		if stream_buf ~= "" then
			vim.schedule(function()
				self:post("main", stream_buf)
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
		self:_refresh_winbar()
		if #self._main_queue > 0 then
			local next_item = table.remove(self._main_queue, 1)
			vim.schedule(function()
				self:_push_to_main(next_item.content, next_item.from)
			end)
		end
	end, function(params)
		-- on_chunk：只收集 text，不影响全局 on_update
		if not params or not params.update then return end
		local kind = params.update.sessionUpdate
		if kind == "agent_message_chunk" then
			local text = self:_extract_text(params.update.content)
			if text ~= "" then stream_buf = stream_buf .. text end
		end
	end)
end

--- 延迟检查队列（等 main chat 空闲后排水）
function Bus:_schedule_main_queue_drain()
	if self._drain_pending then return end
	self._drain_pending = true
	vim.defer_fn(function()
		self._drain_pending = false
		if self._main_busy or #self._main_queue == 0 then return end
		local main_chat = self:_find_main_chat()
		if main_chat and main_chat.streaming then
			self:_schedule_main_queue_drain() -- 还在忙，继续等
			return
		end
		local next_item = table.remove(self._main_queue, 1)
		self:_push_to_main(next_item.content, next_item.from)
	end, 500)
end

--- 查找主 agent 关联的 Chat 实例
function Bus:_find_main_chat()
	local ok, init = pcall(require, "acp.init")
	if not ok then return nil end
	local chats = init._active_chats and init._active_chats() or {}
	local main = self.agents["main"]
	local main_client = main and main.client
	for _, chat in pairs(chats) do
		if main_client and chat.client == main_client then
			return chat
		end
	end
	return nil
end

--- 在主 chat buffer 里标记频道来源消息
--- @param from string 发送者名称
--- @param content string 消息内容
function Bus:_notify_main_chat(from, content)
	local ok, init = pcall(require, "acp.init")
	if not ok then return end
	local chats = init._active_chats and init._active_chats() or {}
	local main = self.agents["main"]
	local main_client = main and main.client
	for _, chat in pairs(chats) do
		if main_client and chat.client == main_client and chat.append_bus_message then
			vim.schedule(function()
				chat:append_bus_message(from, content)
			end)
			return
		end
	end
end

--- 推送消息给指定 agent
--- @param name string 目标 agent
--- @param text string 消息内容
--- @param sender? string 发送者名称，出错时通知此人
function Bus:send_to_agent(name, text, sender)
	local agent = self.agents[name]
	if not agent or not agent.client or not agent.client.alive then
		log("WARN", "send_to_agent  name=" .. name .. "  not alive")
		self:post("系统", name .. " 不在线")
		return
	end
	log("INFO", "send_to_agent  name=" .. name
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
	if agent.chat then
		agent.chat.streaming = true
		agent.chat.stream_started = false
		agent.chat:_refresh_winbar()
	end
	self:_refresh_winbar()
	self:post("系统", "→ " .. name, { no_route = true })
	-- 把 user 消息写入 agent chat buffer
	if agent.chat then
		agent.chat:_append_role("You", text)
	end
	-- 写入 agent 日志：user 消息
	session_write(self.session_dir, "agent-" .. name .. ".log",
		string.format("[%s] [You]  %s\n\n", os.date("%H:%M:%S"), text))
	agent.client:prompt(payload, function(stop_reason, err)
		vim.schedule(function()
			agent.streaming = false
			agent.status = "idle"
			agent.activity = nil
			-- 同步 Chat 的 streaming 状态
			if agent.chat then
				agent.chat.streaming = false
				agent.chat.stream_started = false
				agent.chat:_refresh_winbar()
			end
			self:_refresh_winbar()
			log("INFO", "send_to_agent done  name=" .. name
				.. "  stop=" .. tostring(stop_reason)
				.. "  reply_len=" .. #(agent.stream_buf or ""))
			-- 写入 agent 日志：assistant 回复
			if agent.stream_buf and agent.stream_buf ~= "" then
				session_write(self.session_dir, "agent-" .. name .. ".log",
					string.format("[%s] [%s]  %s\n\n", os.date("%H:%M:%S"), name, agent.stream_buf))
			end
			if not stop_reason or (stop_reason ~= "cancelled" and stop_reason ~= "error") then
				self:post("系统", name .. " 已完成", { no_route = true })
			end
			agent.stream_buf = ""
			if stop_reason == "cancelled" then
				self:post("系统", name .. " 已取消")
			elseif stop_reason == "error" then
				log("ERROR", "send_to_agent error  name=" .. name
					.. "  " .. tostring(err and err.message or "unknown"))
				local detail = ""
				if err then
					detail = " (" .. tostring(err.code or "") .. " " .. tostring(err.message or ""):sub(1, 80) .. ")"
				end
				local err_msg = name .. " 执行出错" .. detail
				self:post("系统", err_msg)
				-- 通知发送者
				if sender and sender ~= "系统" and self.agents[sender] then
					local notify_msg = "@" .. sender .. " " .. err_msg
					self:_send_to(sender, notify_msg, "系统")
				end
			end
		end)
	end)
end

--- 提交输入
function Bus:_submit_input()
	local lines = vim.api.nvim_buf_get_lines(self.input_buf, 0, -1, false)
	local text = vim.trim(table.concat(lines, "\n"))
	if text == "" then
		return
	end
	vim.api.nvim_buf_set_lines(self.input_buf, 0, -1, false, { "" })
	-- 没有 @mention 时默认推给 main
	local has_mention = text:find("@[%w_%-]+")
	if not has_mention then
		text = "@main " .. text
	end
	self:post("你", text)
end

--- 处理 agent 的 session/update
function Bus:_on_agent_update(name, params)
	if not params or not params.update then
		return
	end
	local update = params.update
	local kind = update.sessionUpdate
	if not kind then
		return
	end

	local agent = self.agents[name]
	if not agent then
		return
	end

	-- bus 侧只管状态和日志，buffer 渲染由 Chat._on_update 处理
	if kind == "agent_message_chunk" then
		local text = self:_extract_text(update.content)
		if text ~= "" then
			agent.stream_buf = (agent.stream_buf or "") .. text
			agent.activity = "typing"
			self:_refresh_winbar()
		end
	elseif kind == "tool_call" then
		local title = update.title or "tool"
		log("DEBUG", name .. " tool_call: " .. title)
		agent.activity = title
		self:_refresh_winbar()
	elseif kind == "tool_call_update" then
		local status = update.status or ""
		local title = update.title or "tool"
		log("DEBUG", name .. " tool_update: " .. title .. " " .. status)
	elseif kind == "agent_thought_chunk" then
		agent.activity = "thinking"
		self:_refresh_winbar()
	else
		log("DEBUG", name .. " update: " .. kind)
	end
end

--- 从 content 提取文本（对齐 codecompanion get_renderable_text）
function Bus:_extract_text(content)
	local Client = require("acp.client").Client
	return Client.get_renderable_text(content) or ""
end


--- 渲染单条消息到 buffer（带时间戳和间隔）
function Bus:_render_message(msg)
	if not self.buf or not vim.api.nvim_buf_is_valid(self.buf) then
		return
	end
	vim.bo[self.buf].modifiable = true
	local count = vim.api.nvim_buf_line_count(self.buf)

	-- 计算与上条消息的时间间隔
	local time_str = os.date("%H:%M:%S", msg.timestamp)
	local gap_str = ""
	if self._last_msg_time then
		local gap = msg.timestamp - self._last_msg_time
		if gap >= 60 then
			gap_str = string.format(" (+%dm%ds)", math.floor(gap / 60), gap % 60)
		elseif gap >= 2 then
			gap_str = string.format(" (+%ds)", gap)
		end
	end
	self._last_msg_time = msg.timestamp

	local prefix = "[" .. msg.from .. "]"
	local time_prefix = time_str .. gap_str .. "  "
	local indent = string.rep(" ", #time_prefix + #prefix + 2)
	local lines = {}
	for _, line in ipairs(vim.split(msg.content, "\n", { plain = true })) do
		if #lines == 0 then
			lines[1] = time_prefix .. prefix .. "  " .. line
		else
			lines[#lines + 1] = indent .. line
		end
	end
	vim.api.nvim_buf_set_lines(self.buf, count, count, false, lines)
	vim.bo[self.buf].modifiable = false
	self:_scroll_to_bottom()
	-- 写入频道会话日志
	session_write(self.session_dir, "channel.log",
		string.format("[%s]%s [%s]  %s\n\n", time_str, gap_str, msg.from, msg.content))
end

--- 滚动到底部
function Bus:_scroll_to_bottom()
	if self.win and vim.api.nvim_win_is_valid(self.win) then
		local count = vim.api.nvim_buf_line_count(self.buf)
		pcall(vim.api.nvim_win_set_cursor, self.win, { count, 0 })
	end
end

--- 打开指定 agent 的 Chat 窗口（含输入框）
function Bus:open_agent_buf(name)
	local agent = self.agents[name]
	if not agent or not agent.chat then
		vim.notify("[acp] agent not found: " .. name, vim.log.levels.WARN)
		return
	end
	agent.chat:show()
end
--- @param last_n? number 默认 20
--- @return table[] [{from, content, timestamp}]
function Bus:read(last_n)
	last_n = last_n or 20
	local total = #self.messages
	local start = math.max(1, total - last_n + 1)
	local result = {}
	for i = start, total do
		result[#result + 1] = self.messages[i]
	end
	return result
end

--- 列出所有 agent 状态
--- @return table[] [{name, alive, streaming}]
function Bus:list_agents()
	local result = {}
	for name, agent in pairs(self.agents) do
		result[#result + 1] = {
			name = name,
			kind = agent.kind or "spawned",
			status = agent.status or "idle",
			alive = agent.client and agent.client.alive or false,
			streaming = agent.streaming or false,
		}
	end
	return result
end

--- 保存频道快照
function Bus:save_snapshot()
	if self._saved then return end
	self._saved = true
	local store = require("acp.store")
	store.save(self, self.cwd)
end

--- 从快照恢复：回填历史 + 重新启动 agent
--- @param snapshot table store.load() 返回的快照
function Bus:restore_from_snapshot(snapshot)
	self.channel_id = snapshot.channel_id
	self.cwd = snapshot.cwd or vim.fn.getcwd()

	-- 回填历史消息到 buffer
	if snapshot.history then
		for _, msg in ipairs(snapshot.history) do
			self.messages[#self.messages + 1] = msg
			self:_render_message(msg)
		end
	end

	-- 重新启动各 agent（跳过 kind="local"，新 session 不依赖 session/load）
	if snapshot.agents then
		for _, agent_info in ipairs(snapshot.agents) do
			if agent_info.kind ~= "local" then
				local ok, err = pcall(function()
					self:add_agent(agent_info.name, agent_info.adapter)
				end)
				if not ok then
					self:post("系统", agent_info.name .. " 恢复失败: " .. tostring(err))
				end
			end
		end
	end
end

--- 关闭频道
function Bus:close()
	self:save_snapshot()
	self:_cleanup_agents()
	self.agents = {}
	if self.input_win and vim.api.nvim_win_is_valid(self.input_win) then
		vim.api.nvim_win_close(self.input_win, true)
	end
	if self.win and vim.api.nvim_win_is_valid(self.win) then
		vim.api.nvim_win_close(self.win, true)
	end
	if self.buf and vim.api.nvim_buf_is_valid(self.buf) then
		vim.api.nvim_buf_delete(self.buf, { force = true })
	end
	if self.input_buf and vim.api.nvim_buf_is_valid(self.input_buf) then
		vim.api.nvim_buf_delete(self.input_buf, { force = true })
	end
end

local M = {}
M.Bus = Bus

function M.new()
	return Bus.new()
end

return M
