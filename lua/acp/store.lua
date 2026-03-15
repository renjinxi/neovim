--- ACP 频道持久化：保存/恢复频道快照
local M = {}

local json_encode = vim.fn.json_encode
local json_decode = vim.fn.json_decode

--- cwd 编码：/Users/foo/.config/nvim → Users-foo-.config-nvim
local function encode_cwd(cwd)
	return cwd:gsub("^/", ""):gsub("/", "-")
end

--- 获取存储目录
local function storage_dir(cwd)
	return vim.fn.stdpath("state") .. "/acp-channels/" .. encode_cwd(cwd)
end

--- 保存频道快照
--- @param bus table Bus 实例
--- @param cwd string 工作目录
function M.save(bus, cwd)
	if not bus.messages or #bus.messages == 0 then return end

	local agents = {}
	for name, agent in pairs(bus.agents) do
		agents[#agents + 1] = {
			name = name,
			kind = agent.kind or "spawned",
			adapter = agent.adapter_name or (agent.client and agent.client.adapter and agent.client.adapter.name) or "unknown",
			session_id = agent.client and agent.client.session_id or vim.NIL,
		}
	end

	local snapshot = {
		version = 1,
		channel_id = bus.channel_id,
		saved_at = os.date("%Y-%m-%dT%H:%M:%S"),
		cwd = cwd,
		agents = agents,
		history = bus.messages,
	}

	local dir = storage_dir(cwd)
	vim.fn.mkdir(dir, "p")
	local filepath = dir .. "/" .. bus.channel_id .. ".json"
	local f = io.open(filepath, "w")
	if not f then return end
	f:write(json_encode(snapshot))
	f:close()
end

--- 列出已保存的频道（按时间倒序）
--- @param cwd string
--- @return table[] [{channel_id, saved_at, agents, msg_count, filepath}]
function M.list(cwd)
	local dir = storage_dir(cwd)
	local files = vim.fn.glob(dir .. "/*.json", false, true)
	local result = {}
	for _, filepath in ipairs(files) do
		local f = io.open(filepath, "r")
		if f then
			local ok, snapshot = pcall(json_decode, f:read("*a"))
			f:close()
			if ok and snapshot then
				local agent_names = {}
				for _, a in ipairs(snapshot.agents or {}) do
					agent_names[#agent_names + 1] = a.name .. "(" .. a.adapter .. ")"
				end
				result[#result + 1] = {
					channel_id = snapshot.channel_id,
					saved_at = snapshot.saved_at,
					agents = table.concat(agent_names, ", "),
					msg_count = snapshot.history and #snapshot.history or 0,
					filepath = filepath,
				}
			end
		end
	end
	-- 按 channel_id 倒序
	table.sort(result, function(a, b) return a.channel_id > b.channel_id end)
	return result
end

--- 加载频道快照
--- @param filepath string
--- @return table|nil snapshot
function M.load(filepath)
	local f = io.open(filepath, "r")
	if not f then return nil end
	local ok, snapshot = pcall(json_decode, f:read("*a"))
	f:close()
	if ok then return snapshot end
	return nil
end

--- 删除快照
function M.delete(filepath)
	os.remove(filepath)
end

return M
