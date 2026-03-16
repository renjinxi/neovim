--- ACP 入口：命令注册
local M = {}

local active_chats = {} -- {name -> Chat}
local active_bus = nil -- 单例频道

function M.setup()
	-- :Acp [子命令] — 统一入口
	vim.api.nvim_create_user_command("Acp", function(opts)
		local args = vim.split(opts.args, "%s+")
		local sub = args[1] or ""
		if sub == "" then
			M.toggle_or_start()
		elseif sub == "chat" then
			M.open_chat(args[2] or "claude", { api_num = args[3] and tonumber(args[3]) })
		elseif sub == "bus" then
			local adapter_name = args[2] or "claude"
			local agent_name = args[3]
			if not agent_name or agent_name == "" then
				agent_name = adapter_name .. "-1"
			end
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
		elseif sub == "restore" then
			M.select_bus()
		elseif sub == "stop" then
			M.stop_all()
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
				end, { "bus", "chat", "cli", "list", "restore", "stop" })
			elseif parts[2] == "chat" or parts[2] == "bus" then
				return require("acp.adapter").list()
			elseif parts[2] == "cli" then
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

--- 无参数时：有活跃会话 toggle，没有则开 claude chat
function M.toggle_or_start()
	-- 优先 bus，其次 chat
	local target = active_bus
	if not target then
		for _, chat in pairs(active_chats) do
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

		-- 子 agents
		for name, agent in pairs(active_bus.agents) do
			if agent.kind ~= "local" then
				local status = agent.status or "idle"
				local agent_visible = agent.chat
					and agent.chat.win
					and vim.api.nvim_win_is_valid(agent.chat.win)
				items[#items + 1] = "[agent:" .. name .. "]  " .. status
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
			-- 只注入 ANTHROPIC_ 相关的 env
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
		if active_bus and active_bus.agents["main"] then
			local main = active_bus.agents["main"]
			-- 只在 main 无活跃 client 时注册
			if not main.client or not main.client.alive then
				main.client = client
				main.status = "idle"
				main.adapter_name = adapter_name
				active_bus:_refresh_winbar()
				active_bus:post("系统", "main (" .. adapter_name .. ") 已上线")
			end
		end
	end
	chat:open()
	return chat
end

function M.open_bus(adapter_name, agent_name)
	if not active_bus then
		active_bus = require("acp.bus").new()
		active_bus:open()
		-- 把已有的主 chat client 注册进来（同步检测，on_ready 回调兜底）
		if active_bus.agents["main"] and not active_bus.agents["main"].client then
			for _, chat in pairs(active_chats) do
				if chat.client then
					active_bus.agents["main"].client = chat.client
					active_bus.agents["main"].status = "idle"
					active_bus.agents["main"].adapter_name = chat.adapter_name or "claude"
					active_bus:_refresh_winbar()
					active_bus:post("系统", "main 已上线")
					break
				end
			end
		end
	end
	-- 添加 agent
	active_bus:add_agent(agent_name, adapter_name)
	return active_bus
end

--- 选择并恢复已保存的频道
function M.select_bus()
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
		if active_bus then
			pcall(function() active_bus:close() end)
			active_bus = nil
		end
		-- 创建新 bus 并恢复
		active_bus = require("acp.bus").new()
		active_bus:open()
		active_bus:restore_from_snapshot(snapshot)
	end)
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
