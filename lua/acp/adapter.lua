--- Adapter 注册表：各 CLI 的 spawn 配置
local M = {}

local adapters = {
	claude = {
		name = "claude",
		cmd = "claude-agent-acp",
		args = { "--yolo" }, -- M0 默认 bypass permissions
		get_env = function(opts)
			local env = {}
			if opts.api_num then
				local ok, env_mod = pcall(require, "core.env")
				if ok then
					local n = tostring(opts.api_num)
					local base_url = env_mod.get("CLAUDE_API" .. n .. "_BASE_URL")
					local token = env_mod.get("CLAUDE_API" .. n .. "_TOKEN")
					if base_url then
						env.ANTHROPIC_BASE_URL = base_url
					end
					if token then
						env.ANTHROPIC_AUTH_TOKEN = token
					end
				end
			end
			return env
		end,
	},
	gemini = {
		name = "gemini",
		cmd = "gemini",
		args = { "--experimental-acp", "--yolo" },
		get_env = function(_)
			return {}
		end,
	},
}

--- 获取 adapter 的完整 spawn 配置
--- @param name string "claude" | "gemini"
--- @param opts? table {api_num?, cwd?}
--- @return table {cmd, args, env, name}
function M.get(name, opts)
	opts = opts or {}
	local adapter = adapters[name]
	if not adapter then
		error("unknown adapter: " .. tostring(name))
	end
	local terminal = require("core.terminal")
	local extra_env = adapter.get_env(opts)
	return {
		name = adapter.name,
		cmd = adapter.cmd,
		args = vim.deepcopy(adapter.args),
		env = terminal.get_env(extra_env),
	}
end

--- 列出可用 adapter 名称
function M.list()
	local names = {}
	for k in pairs(adapters) do
		names[#names + 1] = k
	end
	table.sort(names)
	return names
end

return M
