--- ACP 入口：命令注册
local M = {}

local active_chats = {} -- {name -> Chat}
local active_bus = nil -- 单例频道

function M.setup()
	-- :AcpChat [claude|gemini] [api_num]
	vim.api.nvim_create_user_command("AcpChat", function(opts)
		local args = vim.split(opts.args, "%s+")
		local adapter_name = args[1]
		if not adapter_name or adapter_name == "" then
			adapter_name = "claude"
		end
		local api_num = args[2] and tonumber(args[2]) or nil
		M.open_chat(adapter_name, { api_num = api_num })
	end, {
		nargs = "?",
		desc = "ACP: 打开私聊",
		complete = function()
			return require("acp.adapter").list()
		end,
	})

	-- :AcpBus [adapter] [agent_name]
	vim.api.nvim_create_user_command("AcpBus", function(opts)
		local args = vim.split(opts.args, "%s+")
		local adapter_name = args[1]
		if not adapter_name or adapter_name == "" then
			adapter_name = "claude"
		end
		local agent_name = args[2]
		if not agent_name or agent_name == "" then
			agent_name = adapter_name .. "-1"
		end
		M.open_bus(adapter_name, agent_name)
	end, {
		nargs = "?",
		desc = "ACP: 打开频道",
		complete = function()
			return require("acp.adapter").list()
		end,
	})

	-- :AcpStop
	vim.api.nvim_create_user_command("AcpStop", function()
		M.stop_all()
	end, { desc = "ACP: 关闭所有会话" })
end

function M.open_chat(adapter_name, opts)
	local chat = require("acp.chat").new(adapter_name, opts)
	local name = adapter_name .. "_" .. os.time()
	active_chats[name] = chat
	chat:open()
	return chat
end

function M.open_bus(adapter_name, agent_name)
	if not active_bus then
		active_bus = require("acp.bus").new()
		active_bus:open()
	end
	-- 添加 agent
	active_bus:add_agent(agent_name, adapter_name)
	return active_bus
end

function M.stop_all()
	for name, chat in pairs(active_chats) do
		chat:close()
		active_chats[name] = nil
	end
	if active_bus then
		active_bus:close()
		active_bus = nil
	end
end

return M
