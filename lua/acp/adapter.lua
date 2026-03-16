--- Adapter 注册表：各 CLI 的 spawn 配置
local M = {}

local function get_proxy_env()
	local ok, env_mod = pcall(require, "core.env")
	if not ok then return {} end
	local proxy = env_mod.get("CLAUDE_PROXY")
	if not proxy or proxy == "" then return {} end
	return {
		http_proxy = proxy,
		https_proxy = proxy,
		HTTP_PROXY = proxy,
		HTTPS_PROXY = proxy,
		all_proxy = proxy,
	}
end

local adapters = {
	claude = {
		name = "claude",
		description = "Claude Code (Anthropic)",
		cmd = "claude-agent-acp",
		args = { "--yolo" },
		terminal = true, -- 支持 terminal/* 反向请求
		get_env = function(opts)
			local env = get_proxy_env()
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
		description = "Claude Code API1",
		cmd = "claude-agent-acp",
		args = { "--yolo" },
		terminal = true,
		get_env = function(_)
			local env = get_proxy_env()
			local ok, env_mod = pcall(require, "core.env")
			if ok then
				env.ANTHROPIC_BASE_URL = env_mod.get("CLAUDE_API1_BASE_URL")
				env.ANTHROPIC_AUTH_TOKEN = env_mod.get("CLAUDE_API1_TOKEN")
			end
			return env
		end,
	},
	c2 = {
		name = "c2",
		description = "Claude Code API2",
		cmd = "claude-agent-acp",
		args = { "--yolo" },
		terminal = true,
		get_env = function(_)
			local env = get_proxy_env()
			local ok, env_mod = pcall(require, "core.env")
			if ok then
				env.ANTHROPIC_BASE_URL = env_mod.get("CLAUDE_API2_BASE_URL")
				env.ANTHROPIC_AUTH_TOKEN = env_mod.get("CLAUDE_API2_TOKEN")
			end
			return env
		end,
	},
	gemini = {
		name = "gemini",
		description = "Gemini CLI (Google)",
		cmd = "gemini",
		args = { "--yolo", "--acp" },
		terminal = false,
		auth_method = "oauth-personal", -- AuthType.LOGIN_WITH_GOOGLE 的实际值
		get_env = function(_) return {} end,
		get_auth = function(_) return nil end,
	},
	codex = {
		name = "codex",
		description = "Codex CLI (OpenAI)",
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
		config.system_prompt = M.get_bus_system_prompt(opts.agent_name, opts.channel_id)
	end
	return config
end

--- 生成频道模式的 system prompt
--- @param agent_name string
--- @param channel_id? string 频道 ID，用于文件输出目录
--- @return string
function M.get_bus_system_prompt(agent_name, channel_id)
	local tmpfile = "/tmp/acp_msg_" .. agent_name .. ".txt"
	local notes_dir = "notes/acp-bus/" .. (channel_id or "default")
	return string.format(
		[[你是 %s，在一个多 agent 协作频道里。

发消息命令（注意用 $NVIM_LISTEN_ADDRESS 环境变量，不要写死路径）：
echo '内容' > '%s' && nvim --server "$NVIM_LISTEN_ADDRESS" --remote-expr 'luaeval("require(\"acp.rpc\").bus_post_file(\"%s\",\"%s\")")'

频道规则：
- @收件人 开头，默认 @main
- 频道消息 50 字以内，只写结论
- 长内容写文件到 %s/，频道附路径
- 每个任务回复一次，然后等指令]],
		agent_name,
		tmpfile,
		agent_name,
		tmpfile,
		notes_dir
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

--- 列出 adapter 详细信息
--- @return table[] [{name, description}]
function M.list_detailed()
	local result = {}
	for k, v in pairs(adapters) do
		result[#result + 1] = { name = k, description = v.description or "" }
	end
	table.sort(result, function(a, b) return a.name < b.name end)
	return result
end

return M
