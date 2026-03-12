--- ACP 入口：命令注册
local M = {}

local active_chats = {} -- {name -> Chat}
local active_bus = nil -- 单例频道

function M.setup()
	-- :AcpChat [claude|c1|c2|gemini] [api_num]
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
		-- 已有频道：toggle show/hide
		if active_bus then
			local win = active_bus.win
			if win and vim.api.nvim_win_is_valid(win) then
				active_bus:hide()
			else
				active_bus:show()
			end
			return
		end
		M.open_bus(adapter_name, agent_name)
	end, {
		nargs = "?",
		desc = "ACP: 打开/切换频道",
		complete = function()
			return require("acp.adapter").list()
		end,
	})

	-- :AcpToggle — 统一 toggle，主+输入框成对出现
	vim.api.nvim_create_user_command("AcpToggle", function()
		-- 优先 bus，其次 chat
		local target = active_bus
		if not target then
			for _, chat in pairs(active_chats) do
				target = chat
				break
			end
		end
		if not target then
			vim.notify("[acp] 没有活跃的会话，先用 :AcpChat 或 :AcpBus 打开", vim.log.levels.WARN)
			return
		end
		local win = target.win
		if win and vim.api.nvim_win_is_valid(win) then
			target:hide()
		else
			target:show()
		end
	end, { desc = "ACP: toggle 主+输入框" })
	-- :AcpAgents — 统一 picker，列出所有 session，选中 toggle
	vim.api.nvim_create_user_command("AcpAgents", function()
		local items = {}
		local actions = {}

		-- 主 chat sessions
		for _, chat in pairs(active_chats) do
			local visible = chat.win and vim.api.nvim_win_is_valid(chat.win)
			local status = not chat.client and "disconnected"
				or chat.streaming and "streaming"
				or "idle"
			local label = "[chat:" .. chat.adapter_name .. "]  " .. status
				.. (visible and "  ✓" or "")
			items[#items + 1] = label
			actions[#actions + 1] = function()
				if visible then chat:hide() else chat:show() end
			end
		end

		-- 频道主 buffer
		if active_bus then
			local visible = active_bus.win and vim.api.nvim_win_is_valid(active_bus.win)
			items[#items + 1] = "[bus]  频道" .. (visible and "  ✓" or "")
			actions[#actions + 1] = function()
				if visible then active_bus:hide() else active_bus:show() end
			end

			-- 子 agents（只读 buffer，无输入框）
			for name, agent in pairs(active_bus.agents) do
				local status = not agent.client and "disconnected"
					or agent.streaming and "streaming"
					or "idle"
				-- 检查 chat_buf 是否已有窗口
				local agent_visible = false
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					if vim.api.nvim_win_get_buf(win) == agent.chat_buf then
						agent_visible = true
						break
					end
				end
				items[#items + 1] = "[agent:" .. name .. "]  " .. status
					.. (agent_visible and "  ✓" or "")
				actions[#actions + 1] = function()
					if agent_visible then
						-- 关掉显示该 buffer 的窗口
						for _, win in ipairs(vim.api.nvim_list_wins()) do
							if vim.api.nvim_win_get_buf(win) == agent.chat_buf then
								pcall(vim.api.nvim_win_close, win, true)
							end
						end
					else
						active_bus:open_agent_buf(name)
					end
				end
			end
		end

		if #items == 0 then
			vim.notify("[acp] 没有活跃的会话", vim.log.levels.INFO)
			return
		end

		vim.ui.select(items, { prompt = "ACP Sessions" }, function(_, idx)
			if idx then actions[idx]() end
		end)
	end, { desc = "ACP: 选择并 toggle session 窗口" })

	-- :AcpStop
	vim.api.nvim_create_user_command("AcpStop", function()
		M.stop_all()
	end, { desc = "ACP: 关闭所有会话" })
end

function M.open_chat(adapter_name, opts)
	-- 已有同类型 chat：toggle show/hide
	for name, chat in pairs(active_chats) do
		if name:match("^" .. adapter_name .. "_") then
			local win = chat.win
			if win and vim.api.nvim_win_is_valid(win) then
				chat:hide()
			else
				chat:show()
			end
			return chat
		end
	end
	local chat = require("acp.chat").new(adapter_name, opts)
	local name = adapter_name .. "_" .. os.time()
	active_chats[name] = chat
	-- client 就绪后注册为主 agent
	chat.on_ready = function(client)
		if active_bus then
			active_bus.main_client = client
			active_bus:post("系统", "main (" .. adapter_name .. ") 已上线")
		end
	end
	chat:open()
	return chat
end

function M.open_bus(adapter_name, agent_name)
	if not active_bus then
		active_bus = require("acp.bus").new()
		active_bus:open()
		-- 把已有的主 chat client 注册进来（延迟等 client 就绪）
		vim.defer_fn(function()
			if active_bus and not active_bus.main_client then
				for _, chat in pairs(active_chats) do
					if chat.client then
						active_bus.main_client = chat.client
						active_bus:post("系统", "main 已上线")
						break
					end
				end
			end
		end, 500)
	end
	-- 添加 agent
	active_bus:add_agent(agent_name, adapter_name)
	return active_bus
end

--- RPC: 发消息到频道
function M.bus_post(from, content)
	if not active_bus then
		return nil, "bus not open"
	end
	active_bus:post(from or "rpc", content)
	return true
end

--- RPC: 读取最近消息
function M.bus_read(last_n)
	if not active_bus then
		return nil, "bus not open"
	end
	return active_bus:read(last_n)
end

--- RPC: 列出 agent 状态
function M.bus_agents()
	if not active_bus then
		return nil, "bus not open"
	end
	return active_bus:list_agents()
end

--- RPC: 推送消息给指定 agent（先过频道再路由）
function M.bus_send(agent_name, text)
	if not active_bus then
		return nil, "bus not open"
	end
	-- 消息先进频道显示，路由会自动 @mention 触发 send_to_agent
	-- 如果 text 里没有 @agent_name，自动加上
	local content = text
	if not content:find("@" .. agent_name, 1, true) then
		content = "@" .. agent_name .. " " .. text
	end
	active_bus:post("main", content)
	return true
end

--- RPC: 获取 active_bus 实例
function M.get_bus()
	return active_bus
end

--- 供 bus 内部查找主 chat 对象
function M._active_chats()
	return active_chats
end

function M.stop_all()
	for name, chat in pairs(active_chats) do
		pcall(function() chat:close() end)
		active_chats[name] = nil
	end
	if active_bus then
		pcall(function() active_bus:close() end)
		active_bus = nil
	end
end

return M
