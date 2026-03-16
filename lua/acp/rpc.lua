--- ACP 频道 RPC 入口（独立于 agent_api.lua）
--- Claude Code 通过 nvim --server --remote-expr 调用
local M = {}

local acp = require("acp")
local json_encode = vim.fn.json_encode

local LOG_DIR = vim.fn.stdpath("config") .. "/logs"
local LOG_FILE = LOG_DIR .. "/acp-rpc.log"

local function log(level, func_name, msg)
	vim.fn.mkdir(LOG_DIR, "p")
	local f = io.open(LOG_FILE, "a")
	if not f then
		return
	end
	f:write(string.format("%s [%s] %s: %s\n", os.date("%H:%M:%S"), level, func_name, msg))
	f:close()
end

local function ok(data)
	return json_encode({ ok = true, data = data })
end

local function err(msg)
	return json_encode({ ok = false, error = msg })
end

--- 解析 JSON 字符串参数
local function parse_args(raw)
	if not raw or raw == "" then
		return {}
	end
	if type(raw) == "table" then
		return raw
	end
	local success, result = pcall(vim.fn.json_decode, raw)
	if success then
		return result
	end
	return {}
end

--- 开频道 + 添加 agent
--- args: {adapter?: string, agent_name?: string}
function M.bus_open(raw)
	local args = parse_args(raw)
	local adapter_name = args.adapter or "claude"
	local agent_name = args.agent_name or (adapter_name .. "-1")
	local success, open_err = pcall(function()
		acp.open_bus(adapter_name, agent_name)
	end)
	if success then
		return ok({ agent_name = agent_name, adapter = adapter_name })
	else
		return err(tostring(open_err))
	end
end

--- 发消息到频道（从临时文件读取内容，避开引号嵌套）
--- 用法：nvim --server SOCK --remote-expr 'luaeval("require(\"acp.rpc\").bus_post_file(\"FROM\",\"/tmp/acp_msg_FROM.txt\")")'
function M.bus_post_file(from, path)
	if not from or not path then
		return err("missing args")
	end
	local f = io.open(path, "r")
	if not f then
		return err("file not found: " .. path)
	end
	local text = f:read("*a")
	f:close()
	text = text:gsub("\n$", "")
	log("INFO", "bus_post_file", "from=" .. from .. " text=" .. text:sub(1, 50))
	local result, post_err = acp.bus_post(from, text)
	if result then
		return ok(true)
	else
		return err(post_err or "unknown error")
	end
end

--- 发消息到频道
--- args: {text: string, from?: string, channel_id?: string}
function M.bus_post(raw)
	local args = parse_args(raw)
	if not args.text then
		return err("missing text")
	end
	local result, post_err = acp.bus_post(args.from, args.text, args.channel_id)
	if result then
		return ok(true)
	else
		return err(post_err or "unknown error")
	end
end

--- 读取频道消息
--- args: {last_n?: number, channel_id?: string}
function M.bus_read(raw)
	local args = parse_args(raw)
	local result, read_err = acp.bus_read(args.last_n, args.channel_id)
	if result then
		return ok(result)
	else
		return err(read_err or "unknown error")
	end
end

--- 推送消息给指定 agent
--- args: {agent_name: string, text: string, channel_id?: string}
function M.bus_send(raw)
	local args = parse_args(raw)
	if not args.agent_name then
		return err("missing agent_name")
	end
	if not args.text then
		return err("missing text")
	end
	local result, send_err = acp.bus_send(args.agent_name, args.text, args.channel_id)
	if result then
		return ok(true)
	else
		return err(send_err or "unknown error")
	end
end

--- 查询 agent 状态
--- args: {channel_id?: string}
function M.bus_agents(raw)
	local args = parse_args(raw)
	local result, agents_err = acp.bus_agents(args.channel_id)
	if result then
		return ok(result)
	else
		return err(agents_err or "unknown error")
	end
end

--- 列出可用 adapter
function M.list_adapters(_)
	local adapter_mod = require("acp.adapter")
	return ok(adapter_mod.list_detailed())
end

--- 关闭频道
--- args: {channel_id?: string}
function M.bus_stop(raw)
	local args = parse_args(raw)
	local bus = acp.get_bus(args.channel_id)
	if not bus then
		return err("bus not open")
	end
	local registry = require("acp.registry").get()
	local success, stop_err = pcall(function()
		registry:close_channel(args.channel_id)
	end)
	if success then
		return ok(true)
	else
		return err(tostring(stop_err))
	end
end

--- 列出活跃频道
function M.list_channels(_)
	return ok(acp.list_channels())
end

return M
