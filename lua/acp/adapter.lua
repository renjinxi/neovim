--- Adapter 注册表：各 CLI 的 spawn 配置
local M = {}

local adapters = {
	claude = {
		name = "claude",
		cmd = "claude-agent-acp",
		args = { "--yolo" },
		terminal = true, -- 支持 terminal/* 反向请求
		get_env = function(opts)
			local env = {}
			if opts.api_num then
				local ok, env_mod = pcall(require, "core.env")
				if ok then
					local n = tostring(opts.api_num)
					local base_url = env_mod.get("CLAUDE_API" .. n .. "_BASE_URL")
					local token = env_mod.get("CLAUDE_API" .. n .. "_TOKEN")
					if base_url then env.ANTHROPIC_BASE_URL = base_url end
					if token then env.ANTHROPIC_AUTH_TOKEN = token end
				end
			end
			return env
		end,
	},
	c1 = {
		name = "c1",
		cmd = "claude-agent-acp",
		args = { "--yolo" },
		terminal = true,
		get_env = function(_)
			local ok, env_mod = pcall(require, "core.env")
			if ok then
				return {
					ANTHROPIC_BASE_URL = env_mod.get("CLAUDE_API1_BASE_URL"),
					ANTHROPIC_AUTH_TOKEN = env_mod.get("CLAUDE_API1_TOKEN"),
				}
			end
			return {}
		end,
	},
	c2 = {
		name = "c2",
		cmd = "claude-agent-acp",
		args = { "--yolo" },
		terminal = true,
		get_env = function(_)
			local ok, env_mod = pcall(require, "core.env")
			if ok then
				return {
					ANTHROPIC_BASE_URL = env_mod.get("CLAUDE_API2_BASE_URL"),
					ANTHROPIC_AUTH_TOKEN = env_mod.get("CLAUDE_API2_TOKEN"),
				}
			end
			return {}
		end,
	},
	gemini = {
		name = "gemini",
		cmd = "gemini",
		args = { "--yolo", "--acp" },
		terminal = false,
		auth_method = "oauth-personal", -- AuthType.LOGIN_WITH_GOOGLE 的实际值
		get_env = function(_) return {} end,
		get_auth = function(_) return nil end,
	},
	codex = {
		name = "codex",
		cmd = "codex-acp",
		args = {},
		terminal = false,
		auth_method = "chatgpt",
		get_env = function(_)
			local ok, env_mod = pcall(require, "core.env")
			if ok then
				local key = env_mod.get("OPENAI_API_KEY")
				if key and key ~= "" then
					return { OPENAI_API_KEY = key }
				end
			end
			return {}
		end,
	},
}

--- 获取 adapter 的完整 spawn 配置
--- @param name string "claude" | "c1" | "c2" | "gemini" | "codex"
--- @param opts? table {api_num?, cwd?, agent_name?, bus_mode?}
--- @return table {cmd, args, env, name, terminal, system_prompt?}
function M.get(name, opts)
	opts = opts or {}
	local adapter = adapters[name]
	if not adapter then
		error("unknown adapter: " .. tostring(name))
	end
	local terminal = require("core.terminal")
	local extra_env = adapter.get_env(opts)
	local config = {
		name = adapter.name,
		cmd = adapter.cmd,
		args = vim.deepcopy(adapter.args),
		env = terminal.get_env(extra_env),
		terminal = adapter.terminal,
		auth_method = adapter.auth_method, -- 需要 authenticate 步骤的 adapter
		auth_api_key = adapter.get_auth and adapter.get_auth(opts) or nil,
	}
	-- 频道模式：注入 system prompt
	if opts.bus_mode and opts.agent_name then
		config.system_prompt = M.get_bus_system_prompt(opts.agent_name)
	end
	return config
end

--- 生成频道模式的 system prompt
--- @param agent_name string
--- @return string
function M.get_bus_system_prompt(agent_name)
	local sock = vim.env.NVIM_LISTEN_ADDRESS or vim.v.servername
	local tmpfile = "/tmp/acp_msg_" .. agent_name .. ".txt"
	return string.format(
		[[你在一个多 agent 协作频道里。

收到任务后，完成时用以下命令发一次消息到频道：

MSG="你的消息内容"
echo "$MSG" > '%s'
nvim --server '%s' --remote-expr 'luaeval("require(\"acp.rpc\").bus_post_file(\"%s\",\"%s\")")'

规则：
- 任务消息里会说"完成后回复 xxx"，xxx 就是收件人，消息开头写 @xxx
- 没有指定收件人时，默认 @main
- 每个任务只发一次，发完等待下一条指令，不要重复发
- 过程信息不发，只发最终结论]],
		tmpfile,
		sock,
		agent_name,
		tmpfile
	)
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
