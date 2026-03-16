--- 频道逻辑层（无 UI）：消息存储、agent 管理、事件系统
local Agent = require("acp.agent")
local Router = require("acp.router")
local Scheduler = require("acp.scheduler")

local LOG_DIR = vim.fn.stdpath("config") .. "/logs"
local LOG_FILE = LOG_DIR .. "/acp-bus.log"

local function log(level, msg)
	vim.fn.mkdir(LOG_DIR, "p")
	local f = io.open(LOG_FILE, "a")
	if not f then return end
	f:write(string.format("%s [%s] channel: %s\n", os.date("%H:%M:%S"), level, msg))
	f:close()
end

--- 追加内容到频道会话日志文件
local function session_write_file(session_dir, filename, content)
	if not session_dir then return end
	local f = io.open(session_dir .. "/" .. filename, "a")
	if not f then return end
	f:write(content)
	f:close()
end

local Channel = {}
Channel.__index = Channel

function Channel.new()
	local channel_id = os.date("%Y%m%d-%H%M%S")
	local self = setmetatable({
		channel_id = channel_id,
		cwd = vim.fn.getcwd(),
		messages = {},      -- [{from, content, timestamp}]
		agents = {},        -- {name -> Agent}
		session_dir = nil,  -- 本次频道的日志目录
		router = nil,
		scheduler = nil,
		_listeners = {},    -- {event -> [fn]}
		_last_msg_time = nil,
		_saved = false,
		-- P4 频道树预留
		parent = nil,
		children = {},
	}, Channel)
	self.router = Router.new(self)
	self.scheduler = Scheduler.new(self)
	return self
end

--- 事件系统：注册监听
--- @param event string 事件名
--- @param fn function 回调
function Channel:on(event, fn)
	if not self._listeners[event] then
		self._listeners[event] = {}
	end
	self._listeners[event][#self._listeners[event] + 1] = fn
end

--- 事件系统：触发事件
--- @param event string 事件名
function Channel:_emit(event, ...)
	local fns = self._listeners[event]
	if not fns then return end
	for _, fn in ipairs(fns) do
		fn(...)
	end
end

--- 初始化会话目录
function Channel:init_session()
	self.session_dir = LOG_DIR .. "/bus-" .. self.channel_id
	vim.fn.mkdir(self.session_dir, "p")
	session_write_file(self.session_dir, "channel.log", "# 频道会话 " .. self.channel_id .. "\n\n")
end

--- 注册 main agent
function Channel:init_main_agent()
	self.agents["main"] = Agent.new_local()
end

--- 供 scheduler 等子模块使用的会话日志写入
function Channel:session_write(filename, content)
	session_write_file(self.session_dir, filename, content)
end

--- 查找主 agent 关联的 Chat 实例
function Channel:find_main_chat()
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
function Channel:notify_main_chat(from, content)
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

--- 发消息到频道，并按 @mention 路由推送
--- @param from string 发送者
--- @param content string 消息内容
--- @param opts? table {no_route?: bool}
function Channel:post(from, content, opts)
	local msg = {
		from = from,
		content = content,
		timestamp = os.time(),
	}
	self.messages[#self.messages + 1] = msg

	-- 计算时间间隔
	local gap = nil
	if self._last_msg_time then
		gap = msg.timestamp - self._last_msg_time
	end
	self._last_msg_time = msg.timestamp

	-- 写入频道会话日志
	local time_str = os.date("%H:%M:%S", msg.timestamp)
	local gap_str = ""
	if gap then
		if gap >= 60 then
			gap_str = string.format(" (+%dm%ds)", math.floor(gap / 60), gap % 60)
		elseif gap >= 2 then
			gap_str = string.format(" (+%ds)", gap)
		end
	end
	session_write_file(self.session_dir, "channel.log",
		string.format("[%s]%s [%s]  %s\n\n", time_str, gap_str, from, content))

	self:_emit("message", msg, gap)

	if not (opts and opts.no_route) then
		self.router:route(content, from)
	end
end

--- 通知状态变化（供 UI 层刷新）
function Channel:state_changed()
	self:_emit("state_changed")
end

--- 处理 agent 的 session/update
function Channel:_on_agent_update(name, params)
	if not params or not params.update then return end
	local update = params.update
	local kind = update.sessionUpdate
	if not kind then return end

	local agent = self.agents[name]
	if not agent then return end

	if kind == "agent_message_chunk" then
		local text = self:_extract_text(update.content)
		if text ~= "" then
			agent.stream_buf = (agent.stream_buf or "") .. text
			agent.activity = "typing"
			self:state_changed()
		end
	elseif kind == "tool_call" then
		local title = update.title or "tool"
		log("DEBUG", name .. " tool_call: " .. title)
		agent.activity = title
		self:state_changed()
	elseif kind == "tool_call_update" then
		local status = update.status or ""
		local title = update.title or "tool"
		log("DEBUG", name .. " tool_update: " .. title .. " " .. status)
	elseif kind == "agent_thought_chunk" then
		agent.activity = "thinking"
		self:state_changed()
	else
		log("DEBUG", name .. " update: " .. kind)
	end
end

--- 从 content 提取文本（对齐 codecompanion get_renderable_text）
function Channel:_extract_text(content)
	local Client = require("acp.client").Client
	return Client.get_renderable_text(content) or ""
end

--- 添加 agent 到频道
--- @param name string agent 名称
--- @param adapter_name string "claude" | "c1" | "c2" | "gemini"
--- @param opts? table {api_num?, cwd?}
function Channel:add_agent(name, adapter_name, opts)
	log("INFO", "add_agent  name=" .. name .. "  adapter=" .. adapter_name)
	if self.agents[name] and self.agents[name].kind ~= "local" then
		self:post("系统", name .. " 已存在，先 stop 再重新添加")
		return
	end
	opts = opts or {}
	local adapter_mod = require("acp.adapter")
	local chat_mod = require("acp.chat")

	local chat_opts = vim.tbl_extend("force", opts, {
		bus_mode = true,
		agent_name = name,
		channel_id = self.channel_id,
	})

	local adapter_config = adapter_mod.get(adapter_name, chat_opts)

	local chat = chat_mod.new(adapter_name, chat_opts)

	-- 设置回调（替代 bus 引用）
	chat.display_name = name
	chat.on_agent_update = function(params)
		self:_on_agent_update(name, params)
	end
	chat.on_submit = function(text)
		local content = "@" .. name .. " " .. text
		self:post("你", content)
	end
	chat.on_exit_notify = function(code)
		if self.agents[name] then
			self.agents[name].status = "disconnected"
		end
		self:post("系统", name .. " 退出 (code=" .. tostring(code) .. ")")
		self:state_changed()
	end

	-- 先注册 agent
	local agent = Agent.new_spawned(name, {
		adapter_name = adapter_name,
		system_prompt = adapter_config.system_prompt,
		chat = chat,
	})
	self.agents[name] = agent

	chat.on_ready = function(client)
		log("INFO", "add_agent ready  name=" .. name
			.. "  session=" .. tostring(client.session_id))
		if self.agents[name] then
			self.agents[name].client = client
			self.agents[name].status = "idle"
		end
		self:post("系统", name .. " (" .. adapter_name .. ") 已上线")
		self:state_changed()
	end

	chat:open_headless()
	agent.chat_buf = chat.buf
	self:state_changed()
end

--- @param last_n? number 默认 20
--- @return table[] [{from, content, timestamp}]
function Channel:read(last_n)
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
function Channel:list_agents()
	local result = {}
	for name, agent in pairs(self.agents) do
		result[#result + 1] = {
			name = name,
			kind = agent.kind or "spawned",
			status = agent.status or "idle",
			alive = agent:is_alive(),
			streaming = agent.streaming or false,
		}
	end
	return result
end

--- 清理所有 agent 进程
function Channel:_cleanup_agents()
	for _, agent in pairs(self.agents) do
		agent:cleanup()
	end
end

--- 保存频道快照
function Channel:save_snapshot()
	if self._saved then return end
	self._saved = true
	local store = require("acp.store")
	store.save(self, self.cwd)
end

--- 从快照恢复：回填历史 + 重新启动 agent
--- @param snapshot table store.load() 返回的快照
function Channel:restore_from_snapshot(snapshot)
	self.channel_id = snapshot.channel_id
	self.cwd = snapshot.cwd or vim.fn.getcwd()

	-- 回填历史消息
	if snapshot.history then
		for _, msg in ipairs(snapshot.history) do
			self.messages[#self.messages + 1] = msg
			-- 计算间隔
			local gap = nil
			if self._last_msg_time then
				gap = msg.timestamp - self._last_msg_time
			end
			self._last_msg_time = msg.timestamp
			self:_emit("message", msg, gap)
		end
	end

	-- 重新启动各 agent
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

--- 关闭频道（逻辑层）
function Channel:close()
	self:save_snapshot()
	self:_cleanup_agents()
	self.agents = {}
end

return Channel
