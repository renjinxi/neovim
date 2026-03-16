--- 全局注册表：管理所有频道和聊天实例
local Registry = {}
Registry.__index = Registry

local _instance = nil

--- 单例
--- @return table Registry
function Registry.get()
	if not _instance then
		_instance = setmetatable({
			channels = {},        -- {channel_id -> Bus}
			chats = {},           -- {chat_key -> Chat}
			active_channel_id = nil,
		}, Registry)
	end
	return _instance
end

--- 创建频道（返回 Bus facade）
--- @return table Bus
function Registry:create_channel()
	local bus_mod = require("acp.bus")
	local bus = bus_mod.new()
	local channel = bus._channel

	-- 注入回调，消除 channel → init 循环依赖
	channel._find_main_chat_fn = function()
		return self:find_main_chat(channel)
	end
	channel._notify_main_chat_fn = function(from, content)
		self:notify_main_chat(channel, from, content)
	end

	local channel_id = channel.channel_id
	self.channels[channel_id] = bus
	self.active_channel_id = channel_id
	return bus
end

--- 创建独立 Chat
--- @param adapter_name string
--- @param opts? table
--- @return table Chat, string key
function Registry:create_chat(adapter_name, opts)
	local chat = require("acp.chat").new(adapter_name, opts)
	local key = adapter_name .. "_" .. os.time()
	self.chats[key] = chat
	return chat, key
end

--- 获取活跃频道（Bus facade）
--- @param channel_id? string 不传则用 active
--- @return table|nil Bus
function Registry:get_active_channel(channel_id)
	local id = channel_id or self.active_channel_id
	if not id then return nil end
	return self.channels[id]
end

--- 查找与 channel 的 main agent 匹配的 Chat 实例
--- @param channel table Channel
--- @return table|nil Chat
function Registry:find_main_chat(channel)
	local main = channel.agents["main"]
	local main_client = main and main.client
	if not main_client then return nil end
	for _, chat in pairs(self.chats) do
		if chat.client == main_client then
			return chat
		end
	end
	return nil
end

--- 在主 chat buffer 里标记频道来源消息
--- @param channel table Channel
--- @param from string
--- @param content string
function Registry:notify_main_chat(channel, from, content)
	local chat = self:find_main_chat(channel)
	if chat and chat.append_bus_message then
		vim.schedule(function()
			chat:append_bus_message(from, content)
		end)
	end
end

--- 查找可用的 main client（从所有 chats 中）
--- @return table|nil client
--- @return string|nil adapter_name
function Registry:find_main_client()
	for _, chat in pairs(self.chats) do
		if chat.client and chat.client.alive then
			return chat.client, chat.adapter_name
		end
	end
	return nil, nil
end

--- 关闭指定频道
--- @param channel_id? string 不传则关闭 active
function Registry:close_channel(channel_id)
	local id = channel_id or self.active_channel_id
	if not id then return end
	local bus = self.channels[id]
	if bus then
		pcall(function() bus:close() end)
		self.channels[id] = nil
	end
	if self.active_channel_id == id then
		-- 切到下一个频道，或 nil
		self.active_channel_id = next(self.channels)
	end
end

--- 关闭所有
function Registry:stop_all()
	for key, chat in pairs(self.chats) do
		pcall(function() chat:close() end)
		self.chats[key] = nil
	end
	for id, bus in pairs(self.channels) do
		pcall(function() bus:close() end)
		self.channels[id] = nil
	end
	self.active_channel_id = nil
end

--- 列出所有频道 ID
--- @return string[]
function Registry:list_channel_ids()
	local ids = {}
	for id in pairs(self.channels) do
		ids[#ids + 1] = id
	end
	table.sort(ids)
	return ids
end

return Registry
