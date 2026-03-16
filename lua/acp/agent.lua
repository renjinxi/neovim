--- Agent 数据模型 + 生命周期状态
local Agent = {}
Agent.__index = Agent

--- 创建 spawned agent（子 agent，由 bus 管理 client）
--- @param name string agent 名称
--- @param opts table {adapter_name, system_prompt?, chat?}
--- @return table Agent
function Agent.new_spawned(name, opts)
	return setmetatable({
		name = name,
		kind = "spawned",
		adapter_name = opts.adapter_name,
		client = nil,
		chat = opts.chat or nil,
		chat_buf = nil,
		status = "connecting", -- connecting|idle|streaming|disconnected|error
		activity = nil, -- thinking|typing|tool title|...
		streaming = false,
		stream_buf = "",
		system_prompt = opts.system_prompt,
		prompted = false,
		current_task = nil,
		last_rpc_time = nil, -- 最后一次 RPC 回调（bus_post）的时间
		prompt_start_time = nil, -- 当前 prompt 开始时间
	}, Agent)
end

--- 创建 local agent（main，client 由外部注入）
--- @return table Agent
function Agent.new_local()
	return setmetatable({
		name = "main",
		kind = "local",
		adapter_name = "local",
		client = nil,
		chat = nil,
		chat_buf = nil,
		status = "idle",
		activity = nil,
		streaming = false,
		stream_buf = "",
		system_prompt = nil,
		prompted = false,
		current_task = nil,
		last_rpc_time = nil,
		prompt_start_time = nil,
	}, Agent)
end

--- client 是否存活
function Agent:is_alive()
	return self.client and self.client.alive
end

--- 重置流式状态
function Agent:reset_stream()
	self.streaming = false
	self.stream_buf = ""
	self.activity = nil
end

--- 同步关联 Chat 的 streaming 状态
--- @param streaming boolean
function Agent:sync_chat_streaming(streaming)
	if not self.chat then return end
	self.chat.streaming = streaming
	if not streaming then
		self.chat.stream_started = false
	end
	self.chat:_refresh_winbar()
end

--- 清理：停止 client 和关闭 chat
function Agent:cleanup()
	if self.chat then
		pcall(function() self.chat:close() end)
	elseif self.client then
		pcall(function() self.client:stop() end)
	end
end

return Agent
