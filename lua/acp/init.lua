--- ACP 入口：命令注册
local M = {}

--- 获取 registry 单例
local function reg()
	return require("acp.registry").get()
end

function M.setup()
	-- :Acp [子命令] — 统一入口
	vim.api.nvim_create_user_command("Acp", function(opts)
		local args = vim.split(opts.args, "%s+")
		local sub = args[1] or ""
		if sub == "" then
			M.toggle_or_start()
		elseif sub == "chat" then
			-- 解析 --join [agent_name]
			local join = false
			local join_as = nil
			local join_idx = nil
			for i, a in ipairs(args) do
				if a == "--join" then
					join = true
					join_idx = i
					-- 下一个参数如果不是 flag 也不是 adapter 位置参数，就是 agent_name
					if args[i + 1] and not args[i + 1]:match("^%-") then
						join_as = args[i + 1]
					end
					break
				end
			end
			local chat_args = vim.tbl_filter(function(a)
				return a ~= "chat" and a ~= "--join" and a ~= join_as
			end, args)
			local adapter = chat_args[1] or "claude"
			local api_num = chat_args[2] and tonumber(chat_args[2])
			M.open_chat(adapter, { join = join, join_as = join_as, api_num = api_num })
		elseif sub == "bus" then
			local adapter_name = args[2] or "claude"
			local agent_name = args[3]
			if not agent_name or agent_name == "" then
				agent_name = adapter_name .. "-1"
			end
			local active_bus = reg():get_active_channel()
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
		elseif sub == "list" then
			M.show_picker()
		elseif sub == "pick" then
			require("acp.picker").open()
		elseif sub == "restore" then
			M.select_bus()
		elseif sub == "stop" then
			M.stop_all()
		elseif sub == "leave" then
			M.leave_agent(args[2])
		elseif sub == "cli" then
			M.open_native_cli(args[2])
		else
			vim.notify("[acp] 未知子命令: " .. sub, vim.log.levels.ERROR)
		end
	end, {
		nargs = "*",
		desc = "ACP 统一入口",
		complete = function(arg_lead, line)
			local parts = vim.split(line, "%s+")
			if #parts <= 2 then
				return vim.tbl_filter(function(s)
					return s:find(arg_lead, 1, true) == 1
				end, { "bus", "chat", "cli", "leave", "list", "pick", "restore", "stop" })
			elseif parts[2] == "chat" or parts[2] == "bus" then
				return require("acp.adapter").list()
			elseif parts[2] == "cli" or parts[2] == "leave" then
				local active_bus = reg():get_active_channel()
				if active_bus then
					local names = {}
					for name, agent in pairs(active_bus.agents) do
						if agent.kind ~= "local" then
							names[#names + 1] = name
						end
					end
					table.sort(names)
					return names
				end
				return {}
			end
			return {}
		end,
	})
end

--- 主动让 agent 离开频道
--- @param agent_name string
--- @param channel_id? string
function M.bus_leave(agent_name, channel_id)
	local bus = reg():get_active_channel(channel_id)
	if not bus then
		return nil, "bus not open"
	end
	if not agent_name or agent_name == "" then
		return nil, "missing agent_name"
	end
	local agent, remove_err = bus:remove_agent(agent_name)
	if not agent then
		return nil, remove_err
	end
	if agent.chat and agent.chat.stop then
		agent.chat:stop()
	elseif agent.client then
		agent.client:stop()
	end
	return true
end

--- 无参数时：有活跃会话 toggle，没有则开 claude chat
function M.toggle_or_start()
	local r = reg()
	local target = r:get_active_channel()
	if not target then
		for _, chat in pairs(r.chats) do
			target = chat
			break
		end
	end
	if not target then
		M.open_chat("claude", {})
		return
	end
	local win = target.win
	if win and vim.api.nvim_win_is_valid(win) then
		target:hide()
	else
		target:show()
	end
end

--- Picker：列出所有 session，选中 toggle
function M.show_picker()
	local r = reg()
	local items = {}
	local actions = {}

	-- 主 chat sessions
	for _, chat in pairs(r.chats) do
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

	-- 所有频道
	for channel_id, bus in pairs(r.channels) do
		local visible = bus.win and vim.api.nvim_win_is_valid(bus.win)
		local active_mark = channel_id == r.active_channel_id and " *" or ""
		items[#items + 1] = "[bus:" .. channel_id .. "]  频道" .. active_mark .. (visible and "  ✓" or "")
		actions[#actions + 1] = function()
			if visible then bus:hide() else bus:show() end
			r.active_channel_id = channel_id
		end

		-- 子 agents
		for name, agent in pairs(bus.agents) do
			if agent.kind ~= "local" then
				local agent_status = agent.status or "idle"
				local agent_visible = agent.chat
					and agent.chat.win
					and vim.api.nvim_win_is_valid(agent.chat.win)
				items[#items + 1] = "[agent:" .. name .. "]  " .. agent_status
					.. (agent_visible and "  ✓" or "")
				actions[#actions + 1] = function()
					if agent.chat then
						if agent_visible then
							agent.chat:hide()
						else
							agent.chat:show()
						end
					end
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
end

--- 在新 tab 打开原生 CLI（claude --resume）
function M.open_native_cli(agent_name)
	local active_bus = reg():get_active_channel()
	if not active_bus then
		vim.notify("[acp] 没有活跃频道", vim.log.levels.WARN)
		return
	end
	if not agent_name or agent_name == "" then
		vim.notify("[acp] 用法: :Acp cli <agent_name>", vim.log.levels.WARN)
		return
	end
	local agent = active_bus.agents[agent_name]
	if not agent then
		vim.notify("[acp] agent not found: " .. agent_name, vim.log.levels.WARN)
		return
	end
	local session_id = agent.client and agent.client.session_id
	if not session_id then
		vim.notify("[acp] agent 没有 session_id", vim.log.levels.WARN)
		return
	end
	local adapter_name = agent.adapter_name or "claude"
	-- 只支持 claude/c1/c2
	if adapter_name ~= "claude" and adapter_name ~= "c1" and adapter_name ~= "c2" then
		vim.notify("[acp] " .. adapter_name .. " 不支持原生 CLI resume", vim.log.levels.WARN)
		return
	end
	-- 构建 env
	local adapter_config = require("acp.adapter").get(adapter_name, {})
	local env_parts = {}
	if adapter_config.env then
		for k, v in pairs(adapter_config.env) do
			if k:match("^ANTHROPIC_") then
				env_parts[#env_parts + 1] = k .. "=" .. vim.fn.shellescape(v)
			end
		end
	end
	local env_prefix = #env_parts > 0 and (table.concat(env_parts, " ") .. " ") or ""
	local cmd = env_prefix .. "claude --resume " .. session_id
	vim.cmd("tabnew")
	vim.fn.termopen(cmd)
end

function M.open_chat(adapter_name, opts)
	local r = reg()
	opts = opts or {}
	local join = opts.join
	local join_as = opts.join_as
	opts.join = nil -- 不传给 chat 构造
	opts.join_as = nil
	local chat = r:create_chat(adapter_name, opts)
	if join and join_as then
		-- --join <name>：作为指定角色加入频道
		chat.display_name = join_as
		-- 频道回调：输入走频道路由
		chat.on_submit = function(text)
			local active_bus = r:get_active_channel()
			if active_bus then
				active_bus:post("你", "@" .. join_as .. " " .. text)
			end
		end
		-- 频道回调：转发 update
		chat.on_agent_update = function(params)
			local active_bus = r:get_active_channel()
			if active_bus then
				active_bus:_on_agent_update(join_as, params)
			end
		end
		-- 频道回调：进程退出
		chat.on_exit_notify = function(code)
			local active_bus = r:get_active_channel()
			if not active_bus or not active_bus.agents[join_as] then return end
			active_bus.agents[join_as].status = "disconnected"
			active_bus:post("系统", join_as .. " 退出 (code=" .. tostring(code) .. ")")
			active_bus:state_changed()
		end
		chat.on_ready = function(client)
			local active_bus = r:get_active_channel()
			if not active_bus then
				vim.notify("[acp] 没有活跃频道，--join 无效", vim.log.levels.WARN)
				return
			end
			local agent = active_bus.agents[join_as]
			if agent and agent.kind ~= "local" then
				-- 已有同名 agent，替换 client
				agent.client = client
				agent.status = "idle"
				agent.adapter_name = adapter_name
				agent.chat = chat
			else
				-- 注册为新 agent
				local Agent = require("acp.agent")
				local new_agent = Agent.new_spawned(join_as, {
					adapter_name = adapter_name,
					chat = chat,
				})
				new_agent.client = client
				new_agent.status = "idle"
				active_bus.agents[join_as] = new_agent
			end
			active_bus:_refresh_winbar()
			active_bus:post("系统", join_as .. " (" .. adapter_name .. ") 已上线 (--join)")
			active_bus:state_changed()
		end
	elseif join then
		-- --join：就绪后强制注册为频道 main agent
		chat.on_ready = function(client)
			local active_bus = r:get_active_channel()
			if not active_bus then
				vim.notify("[acp] 没有活跃频道，--join 无效", vim.log.levels.WARN)
				return
			end
			local main = active_bus.agents["main"]
			if not main then return end
			main.client = client
			main.status = "idle"
			main.adapter_name = adapter_name
			active_bus:_refresh_winbar()
			active_bus:post("系统", "main (" .. adapter_name .. ") 已上线 (--join)")
		end
	else
		-- 默认：只在 main 无活跃 client 时自动注册
		chat.on_ready = function(client)
			local active_bus = r:get_active_channel()
			if active_bus and active_bus.agents["main"] then
				local main = active_bus.agents["main"]
				if not main.client or not main.client.alive then
					main.client = client
					main.status = "idle"
					main.adapter_name = adapter_name
					active_bus:_refresh_winbar()
					active_bus:post("系统", "main (" .. adapter_name .. ") 已上线")
				end
			end
		end
	end
	chat:open()
	return chat
end

function M.open_bus(adapter_name, agent_name)
	local r = reg()
	local active_bus = r:get_active_channel()
	if not active_bus then
		active_bus = r:create_channel()
		active_bus:open()
		-- 把已有的主 chat client 注册进来
		if active_bus.agents["main"] and not active_bus.agents["main"].client then
			local client, client_adapter = r:find_main_client()
			if client then
				active_bus.agents["main"].client = client
				active_bus.agents["main"].status = "idle"
				active_bus.agents["main"].adapter_name = client_adapter or "claude"
				active_bus:_refresh_winbar()
				active_bus:post("系统", "main 已上线")
			end
		end
	end
	-- 添加 agent
	active_bus:add_agent(agent_name, adapter_name)
	return active_bus
end

--- 选择并恢复已保存的频道
function M.select_bus()
	local r = reg()
	local store = require("acp.store")
	local cwd = vim.fn.getcwd()
	local channels = store.list(cwd)
	if #channels == 0 then
		vim.notify("[acp] 当前目录没有已保存的频道", vim.log.levels.INFO)
		return
	end
	local items = {}
	for _, ch in ipairs(channels) do
		items[#items + 1] = string.format("%s  [%s]  %d条消息", ch.channel_id, ch.agents, ch.msg_count)
	end
	vim.ui.select(items, { prompt = "恢复频道" }, function(_, idx)
		if not idx then return end
		local selected = channels[idx]
		local snapshot = store.load(selected.filepath)
		if not snapshot then
			vim.notify("[acp] 快照加载失败", vim.log.levels.ERROR)
			return
		end
		-- 关闭当前频道（如果有）
		r:close_channel()
		-- 创建新频道并恢复
		local bus = r:create_channel()
		bus:open()
		bus:restore_from_snapshot(snapshot)
	end)
end

--- RPC: 发消息到频道
--- @param from? string
--- @param content string
--- @param channel_id? string
function M.bus_post(from, content, channel_id)
	local bus = reg():get_active_channel(channel_id)
	if not bus then
		return nil, "bus not open"
	end
	bus:post(from or "rpc", content)
	return true
end

--- RPC: 读取最近消息
--- @param last_n? number
--- @param channel_id? string
function M.bus_read(last_n, channel_id)
	local bus = reg():get_active_channel(channel_id)
	if not bus then
		return nil, "bus not open"
	end
	return bus:read(last_n)
end

--- RPC: 列出 agent 状态
--- @param channel_id? string
function M.bus_agents(channel_id)
	local bus = reg():get_active_channel(channel_id)
	if not bus then
		return nil, "bus not open"
	end
	return bus:list_agents()
end

--- RPC: 推送消息给指定 agent
--- @param agent_name string
--- @param text string
--- @param channel_id? string
function M.bus_send(agent_name, text, channel_id)
	local bus = reg():get_active_channel(channel_id)
	if not bus then
		return nil, "bus not open"
	end
	local content = text
	if not content:find("@" .. agent_name, 1, true) then
		content = "@" .. agent_name .. " " .. text
	end
	bus:post("main", content)
	return true
end

function M.leave_agent(agent_name)
	local ok, leave_err = M.bus_leave(agent_name)
	if ok then
		return
	end
	vim.notify("[acp] " .. tostring(leave_err), vim.log.levels.WARN)
end

--- RPC: 获取 active bus 实例
--- @param channel_id? string
function M.get_bus(channel_id)
	return reg():get_active_channel(channel_id)
end

--- RPC: 列出所有频道 ID
function M.list_channels()
	return reg():list_channel_ids()
end

function M.stop_all()
	reg():stop_all()
end

return M
