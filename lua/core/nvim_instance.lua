local M = {}

local function mkdir_p(path)
	vim.fn.mkdir(path, "p")
end

local function append_log(log_file, fields)
	local ok, f = pcall(io.open, log_file, "a")
	if not ok or not f then
		return
	end
	f:write(table.concat(fields, "\t") .. "\n")
	f:close()
end

local function ensure_servername()
	if vim.v.servername and vim.v.servername ~= "" then
		return vim.v.servername
	end

	local run_dir = vim.fn.stdpath("run")
	if run_dir == nil or run_dir == "" then
		run_dir = "/tmp"
	end
	local sock_dir = run_dir .. "/nvim-agent"
	mkdir_p(sock_dir)

	local sock = string.format("%s/nvim-%d.sock", sock_dir, vim.fn.getpid())
	local ok, addr = pcall(vim.fn.serverstart, sock)
	if ok and addr and addr ~= "" then
		return addr
	end

	-- fallback: 让 nvim 自行分配地址
	local ok_auto, auto_addr = pcall(vim.fn.serverstart)
	if ok_auto and auto_addr and auto_addr ~= "" then
		return auto_addr
	end
	return vim.v.servername or ""
end

function M.setup()
	if vim.g.vscode then
		return
	end

	local server = ensure_servername()
	local pid = tostring(vim.fn.getpid())
	local log_dir = vim.fn.stdpath("state") .. "/agent-logs"
	mkdir_p(log_dir)
	local log_file = string.format("%s/nvim-instance-%s.log", log_dir, pid)

	-- 这些变量会被 :terminal 打开的子进程继承
	vim.env.NVIM_LISTEN_ADDRESS = server
	vim.env.NVIM_INSTANCE_ID = pid
	vim.env.NVIM_AGENT = "1"
	vim.env.NVIM_AGENT_ROLE = "interactive"
	vim.env.NVIM_AGENT_LOG_DIR = log_dir
	vim.env.NVIM_AGENT_LOG_FILE = log_file
	vim.env.NVIM_AGENT_CONFIG_DIR = vim.fn.stdpath("config")
	vim.env.NVIM_AGENT_API = "1"

	append_log(log_file, {
		os.date("!%Y-%m-%dT%H:%M:%SZ"),
		"event=nvim_start",
		"pid=" .. pid,
		"server=" .. (server or ""),
		"cwd=" .. vim.fn.getcwd(),
	})

	local group = vim.api.nvim_create_augroup("NvimAgentObservability", { clear = true })
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			append_log(log_file, {
				os.date("!%Y-%m-%dT%H:%M:%SZ"),
				"event=nvim_leave",
				"pid=" .. pid,
				"server=" .. (vim.env.NVIM_LISTEN_ADDRESS or ""),
			})
		end,
	})

	vim.api.nvim_create_user_command("NvimInstanceEnv", function()
		local lines = {
			"NVIM_LISTEN_ADDRESS=" .. (vim.env.NVIM_LISTEN_ADDRESS or ""),
			"NVIM_INSTANCE_ID=" .. (vim.env.NVIM_INSTANCE_ID or ""),
			"NVIM_AGENT=" .. (vim.env.NVIM_AGENT or ""),
			"NVIM_AGENT_ROLE=" .. (vim.env.NVIM_AGENT_ROLE or ""),
			"NVIM_AGENT_LOG_DIR=" .. (vim.env.NVIM_AGENT_LOG_DIR or ""),
			"NVIM_AGENT_LOG_FILE=" .. (vim.env.NVIM_AGENT_LOG_FILE or ""),
			"NVIM_AGENT_CONFIG_DIR=" .. (vim.env.NVIM_AGENT_CONFIG_DIR or ""),
		}
		vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Nvim Instance Env" })
	end, { desc = "Show nvim instance env for AI agents" })
end

return M
