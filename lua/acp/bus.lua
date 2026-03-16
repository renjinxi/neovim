--- 频道 Facade：组合 Channel + ChannelView，保持 API 兼容
local Channel = require("acp.channel")
local ChannelView = require("acp.channel_view")

local Bus = {}

--- __index 代理：优先 Bus 自身方法，再代理 channel/view 的字段
Bus.__index = function(self, key)
	-- Bus 自身方法
	local v = rawget(Bus, key)
	if v ~= nil then return v end
	-- view 字段代理
	if key == "win" then return rawget(self, "_view") and self._view.win end
	if key == "input_win" then return rawget(self, "_view") and self._view.input_win end
	if key == "buf" then return rawget(self, "_view") and self._view.buf end
	if key == "input_buf" then return rawget(self, "_view") and self._view.input_buf end
	-- channel 字段代理
	local ch = rawget(self, "_channel")
	if ch then
		local cv = rawget(ch, key)
		if cv ~= nil then return cv end
	end
	return nil
end

function Bus.new()
	local channel = Channel.new()
	local view = ChannelView.new(channel)
	local self = setmetatable({
		_channel = channel,
		_view = view,
	}, Bus)
	return self
end

--- 打开频道
function Bus:open()
	self._channel:init_session()
	self._channel:init_main_agent()
	self._view:open()
end

--- 只关窗口
function Bus:hide()
	self._view:hide()
end

--- 重新打开窗口
function Bus:show()
	return self._view:show()
end

--- 关闭频道
function Bus:close()
	self._channel:close()
	self._view:close()
end

--- 发消息
function Bus:post(from, content, opts)
	self._channel:post(from, content, opts)
end

--- 添加 agent
function Bus:add_agent(name, adapter_name, opts)
	self._channel:add_agent(name, adapter_name, opts)
end

--- 通知状态变化
function Bus:state_changed()
	self._channel:state_changed()
end

--- 刷新 winbar（兼容旧调用）
function Bus:_refresh_winbar()
	self._view:_refresh_winbar()
end

--- 处理 agent update
function Bus:_on_agent_update(name, params)
	self._channel:_on_agent_update(name, params)
end

--- 从 content 提取文本
function Bus:_extract_text(content)
	return self._channel:_extract_text(content)
end

--- 会话日志写入
function Bus:session_write(filename, content)
	self._channel:session_write(filename, content)
end

--- 查找主 Chat
function Bus:find_main_chat()
	return self._channel:find_main_chat()
end

--- 通知主 Chat
function Bus:notify_main_chat(from, content)
	self._channel:notify_main_chat(from, content)
end

--- 读取消息
function Bus:read(last_n)
	return self._channel:read(last_n)
end

--- 列出 agent
function Bus:list_agents()
	return self._channel:list_agents()
end

--- 保存快照
function Bus:save_snapshot()
	self._channel:save_snapshot()
end

--- 恢复快照
function Bus:restore_from_snapshot(snapshot)
	self._channel:restore_from_snapshot(snapshot)
end

--- 打开 agent buffer
function Bus:open_agent_buf(name)
	self._view:open_agent_buf(name)
end

local M = {}
M.Bus = Bus

function M.new()
	return Bus.new()
end

return M
