--- ACP Client：spawn 进程、ACP 握手、prompt、流式接收
local jsonrpc = require("acp.jsonrpc")
local uv = vim.uv

-- 日志文件：~/.config/nvim/logs/acp-client.log
local LOG_FILE = vim.fn.stdpath("config") .. "/logs/acp-client.log"

local function write_log(msg)
	vim.fn.mkdir(vim.fn.fnamemodify(LOG_FILE, ":h"), "p")
	local f = io.open(LOG_FILE, "a")
	if not f then return end
	f:write(os.date("%H:%M:%S") .. "  " .. msg .. "\n")
	f:close()
end

local Client = {}
Client.__index = Client

--- 实例日志（带 agent 名）
function Client:_log(msg)
	local name = self.adapter and self.adapter.name or "?"
	write_log("[" .. name .. "]  " .. msg)
end

--- 创建新 client
--- @param adapter_config table {cmd, args, env, name}
function Client.new(adapter_config)
	return setmetatable({
		adapter = adapter_config,
		handle = nil,
		stdin = nil,
		stdout = nil,
		stderr = nil,
		pid = nil,
		alive = false,
		line_buf = jsonrpc.line_buffer(),
		pending = {}, -- {[id] = callback(result, err)}
		session_id = nil,
		agent_caps = nil,
		agent_info = nil, -- initialize 返回的完整信息
		on_update = nil, -- session/update 回调
		on_exit = nil,
	}, Client)
end

--- 启动进程 + ACP 握手
--- @param opts table {cwd?, on_update?, on_exit?}
function Client:start(opts)
	opts = opts or {}
	self.on_update = opts.on_update
	self.on_exit = opts.on_exit

	-- 创建 pipes
	self.stdin = uv.new_pipe()
	self.stdout = uv.new_pipe()
	self.stderr = uv.new_pipe()

	local cwd = opts.cwd or vim.fn.getcwd()
	local t0 = os.clock()
	self:_log("spawn  cmd=" .. self.adapter.cmd .. "  cwd=" .. cwd)

	-- spawn
	self.handle, self.pid = uv.spawn(self.adapter.cmd, {
		args = self.adapter.args,
		env = self:_env_list(),
		stdio = { self.stdin, self.stdout, self.stderr },
		cwd = cwd,
	}, function(code, signal)
		vim.schedule(function()
			self:_log("exit  code=" .. tostring(code) .. "  signal=" .. tostring(signal))
			self.alive = false
			if self.on_exit then
				self.on_exit(code, signal)
			end
		end)
	end)

	if not self.handle then
		self:_log("spawn FAILED  cmd=" .. self.adapter.cmd)
		error("spawn failed: " .. self.adapter.cmd .. " (pid=" .. tostring(self.pid) .. ")")
	end
	self:_log("spawned  pid=" .. tostring(self.pid))

	-- 读 stdout
	self.stdout:read_start(function(err, chunk)
		if err or not chunk then
			return
		end
		vim.schedule(function()
			local lines = self.line_buf:feed(chunk)
			for _, line in ipairs(lines) do
				local msg = jsonrpc.decode(line)
				if msg then
					self:_dispatch(msg)
				end
			end
		end)
	end)

	-- stderr → 日志文件（不再静默）
	self.stderr:read_start(function(_, chunk)
		if chunk and chunk ~= "" then
			vim.schedule(function()
				self:_log("stderr  " .. vim.trim(chunk):sub(1, 200))
			end)
		end
	end)

	-- ACP 握手：initialize（capabilities 根据 adapter 决定）
	local t1 = os.clock()
	local caps = { fs = { readTextFile = true, writeTextFile = true } }
	if self.adapter.terminal ~= false then
		caps.terminal = true
	end
	local init_result, init_err = self:_request_sync("initialize", {
		protocolVersion = 1,
		clientInfo = { name = "nvim-acp", version = "0.1.0" },
		clientCapabilities = caps,
	}, 15000)
	if init_err then
		self:_log("initialize FAILED  err=" .. tostring(init_err))
		self:stop()
		error("initialize failed: " .. tostring(init_err))
	end
	self:_log("initialize ok  elapsed=" .. math.floor((os.clock()-t1)*1000) .. "ms  proto=" .. tostring(init_result and init_result.protocolVersion))
	self.agent_info = init_result or {}
	self.agent_caps = self.agent_info.agentCapabilities or {}

	-- ACP 握手：session/new
	local t2 = os.clock()
	local session_args = { cwd = cwd, mcpServers = {} }
	local session_result, session_err = self:_request_sync("session/new", session_args, 15000)
	if session_err then
		self:_log("session/new FAILED  err=" .. tostring(session_err))
		self:stop()
		error("session/new failed: " .. tostring(session_err))
	end
	self.session_id = session_result and session_result.sessionId
	self:_log("session/new ok  elapsed=" .. math.floor((os.clock()-t2)*1000) .. "ms  session=" .. tostring(self.session_id))
	self:_log("ready  total_handshake=" .. math.floor((os.clock()-t0)*1000) .. "ms")
	self.alive = true
end

--- 发送 prompt（异步）
--- @param text string 用户输入文本
--- @param on_done? function(stop_reason)
function Client:prompt(text, on_done)
	if not self.alive or not self.session_id then
		vim.notify("[acp] client not ready", vim.log.levels.ERROR)
		return
	end
	local t0 = os.clock()
	local name = self.adapter and self.adapter.name or "?"
	local prompt = { { type = "text", text = text } }
	self:_send_request("session/prompt", {
		sessionId = self.session_id,
		prompt = prompt,
	}, function(result, err)
		local elapsed_ms = math.floor((os.clock() - t0) * 1000)
		self:_log("prompt done  agent=" .. name .. "  elapsed=" .. elapsed_ms .. "ms  stop=" .. tostring(result and result.stopReason or err and "error" or "?"))
		if on_done then
			local reason = result and result.stopReason or (err and "error" or "unknown")
			on_done(reason)
		end
	end)
	self:_log("prompt sent  agent=" .. name .. "  len=" .. #text)
end

--- 取消当前 prompt
function Client:cancel()
	if self.session_id then
		self:_send_notification("session/cancel", { sessionId = self.session_id })
	end
end

--- 停止进程
function Client:stop()
	self.alive = false
	-- 清理所有子终端
	if self._terminals then
		for tid, t in pairs(self._terminals) do
			for _, pipe_name in ipairs({ "stdin", "stdout", "stderr" }) do
				local pipe = t[pipe_name]
				if pipe and not pipe:is_closing() then
					pcall(function()
						if pipe_name ~= "stdin" then
							pipe:read_stop()
						end
						pipe:close()
					end)
				end
			end
			if t.handle and not t.handle:is_closing() then
				pcall(function()
					t.handle:kill("sigterm")
				end)
			end
		end
		self._terminals = {}
	end
	if self.stdin then
		pcall(function()
			self.stdin:close()
		end)
	end
	if self.stdout then
		pcall(function()
			self.stdout:read_stop()
			self.stdout:close()
		end)
	end
	if self.stderr then
		pcall(function()
			self.stderr:read_stop()
			self.stderr:close()
		end)
	end
	if self.handle then
		pcall(function()
			self.handle:kill("sigterm")
		end)
		vim.defer_fn(function()
			if self.handle and not self.handle:is_closing() then
				pcall(function()
					self.handle:kill("sigkill")
				end)
			end
		end, 500)
	end
end

--- 发送 request（异步）
function Client:_send_request(method, params, callback)
	local id = jsonrpc.next_id()
	self.pending[id] = callback
	self:_write(jsonrpc.encode_request(id, method, params))
end

--- 发送 request（同步，vim.wait 阻塞）
function Client:_request_sync(method, params, timeout_ms)
	local done = false
	local result, error_obj
	self:_send_request(method, params, function(res, err)
		result = res
		error_obj = err
		done = true
	end)
	vim.wait(timeout_ms or 10000, function()
		return done
	end, 50)
	if not done then
		return nil, "timeout waiting for " .. method
	end
	if error_obj then
		return nil, error_obj.message or vim.inspect(error_obj)
	end
	return result
end

--- 发送 notification
function Client:_send_notification(method, params)
	self:_write(jsonrpc.encode_notification(method, params))
end

--- 写入 stdin
function Client:_write(json_str)
	if self.stdin and not self.stdin:is_closing() then
		self.stdin:write(json_str .. "\n")
	end
end

--- 消息分发
function Client:_dispatch(msg)
	if jsonrpc.is_response(msg) then
		local cb = self.pending[msg.id]
		if cb then
			self.pending[msg.id] = nil
			if msg.error then
				cb(nil, msg.error)
			else
				cb(msg.result)
			end
		end
	elseif jsonrpc.is_request(msg) then
		self:_handle_request(msg)
	elseif jsonrpc.is_notification(msg) then
		self:_handle_notification(msg)
	end
end

--- 处理 agent 发来的 request（反向调用）
function Client:_handle_request(msg)
	local method = msg.method
	local params = msg.params or {}

	if method == "session/request_permission" then
		-- M0: 自动 allow（yolo 模式下不应该收到，但以防万一）
		local options = params.options or {}
		local allow_id = nil
		for _, opt in ipairs(options) do
			if opt.kind == "allow_once" or opt.kind == "allow_always" then
				allow_id = opt.optionId
				break
			end
		end
		self:_write(jsonrpc.encode_response(msg.id, {
			outcome = { outcome = "selected", optionId = allow_id or "allow" },
		}))
	elseif method == "fs/read_text_file" then
		local path = params.path
		if not path then
			self:_write(jsonrpc.encode_error(msg.id, -32602, "missing path"))
			return
		end
		-- 存在性检查
		if not vim.uv.fs_stat(path) then
			-- agent 可能要创建新文件，返回空内容而不是报错
			self:_write(jsonrpc.encode_response(msg.id, { content = "" }))
			return
		end
		local f = io.open(path, "r")
		if not f then
			self:_write(jsonrpc.encode_error(msg.id, -32000, "cannot open: " .. path))
			return
		end
		local data = f:read("*a")
		f:close()
		-- 支持 line + limit 分页（对齐 codecompanion fs.lua）
		local line = params.line ~= vim.NIL and tonumber(params.line) or nil
		local limit = params.limit ~= vim.NIL and tonumber(params.limit) or nil
		if line or limit then
			local lines = vim.split(data, "\n", { plain = true })
			local total = #lines
			local start = math.max(1, line or 1)
			local content
			if limit and limit > 0 then
				local finish = math.min(start + limit - 1, total)
				if start > total then
					content = ""
				else
					content = table.concat(vim.list_slice(lines, start, finish), "\n")
				end
			else
				content = start > total and "" or table.concat(vim.list_slice(lines, start, total), "\n")
			end
			self:_write(jsonrpc.encode_response(msg.id, { content = content }))
		else
			self:_write(jsonrpc.encode_response(msg.id, { content = data }))
		end
	elseif method == "fs/write_text_file" then
		local path = params.path
		local content = params.content
		if not path or content == nil then
			self:_write(jsonrpc.encode_error(msg.id, -32602, "missing path or content"))
			return
		end
		-- 优先写已打开的 buffer，避免 buffer/磁盘不同步
		local abs_path = vim.fn.fnamemodify(path, ":p")
		local written = false
		for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_get_name(bufnr) == abs_path then
				local lines = vim.split(content, "\n", { plain = true })
				if lines[#lines] == "" then lines[#lines] = nil end
				vim.schedule(function()
					vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
					vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent! write") end)
				end)
				written = true
				break
			end
		end
		if not written then
			vim.fn.mkdir(vim.fn.fnamemodify(abs_path, ":h"), "p")
			local f = io.open(abs_path, "w")
			if not f then
				self:_write(jsonrpc.encode_error(msg.id, -32000, "cannot open: " .. path))
				return
			end
			f:write(content)
			f:close()
		end
		self:_write(jsonrpc.encode_response(msg.id, vim.empty_dict()))
	elseif method == "terminal/create" then
		self:_handle_terminal_create(msg.id, params)
	elseif method == "terminal/output" then
		self:_handle_terminal_output(msg.id, params)
	elseif method == "terminal/wait_for_exit" then
		self:_handle_terminal_wait(msg.id, params)
	elseif method == "terminal/kill" then
		self:_handle_terminal_kill(msg.id, params)
	elseif method == "terminal/release" then
		self:_handle_terminal_release(msg.id, params)
	else
		self:_write(jsonrpc.encode_error(msg.id, -32601, "method not found: " .. tostring(method)))
	end
end

-- ============================================================================
-- Terminal 反向请求：agent 通过这些方法执行 bash 命令
-- ============================================================================

--- terminal/create：启动子进程，返回 terminalId
function Client:_handle_terminal_create(id, params)
	local cmd = params.command
	if not cmd then
		self:_write(jsonrpc.encode_error(id, -32602, "missing command"))
		return
	end

	local args = params.args or {}
	local cwd = params.cwd
	local env_map = params.env
	local byte_limit = params.outputByteLimit or (1024 * 1024)
	local t0 = os.clock()
	self:_log("terminal/create  cmd=" .. cmd .. "  cwd=" .. tostring(cwd))
	local term_stdout = uv.new_pipe()
	local term_stderr = uv.new_pipe()
	local term_stdin = uv.new_pipe()

	-- 构建 env list
	local env_list = nil
	if env_map then
		env_list = {}
		-- 先继承当前进程环境
		for k, v in pairs(self.adapter.env or {}) do
			env_list[#env_list + 1] = k .. "=" .. tostring(v)
		end
		-- 覆盖 agent 指定的
		for k, v in pairs(env_map) do
			env_list[#env_list + 1] = k .. "=" .. tostring(v)
		end
	end

	local term_handle, term_pid = uv.spawn(cmd, {
		args = args,
		stdio = { term_stdin, term_stdout, term_stderr },
		cwd = cwd,
		env = env_list,
	}, function(code, signal)
		vim.schedule(function()
			local tid = tostring(term_pid)
			local t = self._terminals and self._terminals[tid]
			if t then
				t.exit_code = code
				t.signal = signal
				t.exited = true
				-- 唤醒 wait_for_exit
				if t.wait_cb then
					t.wait_cb()
					t.wait_cb = nil
				end
			end
		end)
	end)

	if not term_handle then
		self:_log("terminal/create FAILED  cmd=" .. cmd)
		self:_write(jsonrpc.encode_error(id, -32000, "spawn failed: " .. cmd))
		return
	end

	local tid = tostring(term_pid)
	self:_log("terminal/create ok  tid=" .. tid .. "  pid=" .. tostring(term_pid) .. "  elapsed=" .. math.floor((os.clock()-t0)*1000) .. "ms")
	if not self._terminals then
		self._terminals = {}
	end

	self._terminals[tid] = {
		handle = term_handle,
		pid = term_pid,
		stdin = term_stdin,
		stdout = term_stdout,
		stderr = term_stderr,
		output = {},
		output_bytes = 0,
		byte_limit = byte_limit,
		truncated = false,
		exited = false,
		exit_code = nil,
		signal = nil,
		wait_cb = nil,
	}

	local t = self._terminals[tid]

	-- 收集 stdout
	term_stdout:read_start(function(err, chunk)
		if err or not chunk then
			return
		end
		vim.schedule(function()
			if t.output_bytes < t.byte_limit then
				t.output[#t.output + 1] = chunk
				t.output_bytes = t.output_bytes + #chunk
			else
				t.truncated = true
			end
		end)
	end)

	-- 收集 stderr（合并到 output）
	term_stderr:read_start(function(err, chunk)
		if err or not chunk then
			return
		end
		vim.schedule(function()
			if t.output_bytes < t.byte_limit then
				t.output[#t.output + 1] = chunk
				t.output_bytes = t.output_bytes + #chunk
			else
				t.truncated = true
			end
		end)
	end)

	self:_write(jsonrpc.encode_response(id, { terminalId = tid }))
end

--- terminal/output：读取已收集的输出
function Client:_handle_terminal_output(id, params)
	local tid = params.terminalId
	local t = self._terminals and self._terminals[tid]
	if not t then
		self:_write(jsonrpc.encode_error(id, -32000, "unknown terminal: " .. tostring(tid)))
		return
	end
	local output = table.concat(t.output)
	local resp = {
		output = output,
		truncated = t.truncated,
	}
	if t.exited then
		resp.exitStatus = { exitCode = t.exit_code, signal = t.signal }
	end
	self:_write(jsonrpc.encode_response(id, resp))
end

--- terminal/wait_for_exit：阻塞等待进程退出
function Client:_handle_terminal_wait(id, params)
	local tid = params.terminalId
	local t = self._terminals and self._terminals[tid]
	if not t then
		self:_write(jsonrpc.encode_error(id, -32000, "unknown terminal: " .. tostring(tid)))
		return
	end
	if t.exited then
		self:_write(jsonrpc.encode_response(id, { exitCode = t.exit_code, signal = t.signal }))
		return
	end
	-- 还没退出，注册回调
	t.wait_cb = function()
		self:_write(jsonrpc.encode_response(id, { exitCode = t.exit_code, signal = t.signal }))
	end
end

--- terminal/kill：杀进程
function Client:_handle_terminal_kill(id, params)
	local tid = params.terminalId
	local t = self._terminals and self._terminals[tid]
	if not t then
		self:_write(jsonrpc.encode_error(id, -32000, "unknown terminal: " .. tostring(tid)))
		return
	end
	if t.handle and not t.handle:is_closing() then
		pcall(function()
			t.handle:kill("sigterm")
		end)
	end
	self:_write(jsonrpc.encode_response(id, {}))
end

--- terminal/release：释放终端资源
function Client:_handle_terminal_release(id, params)
	local tid = params.terminalId
	local t = self._terminals and self._terminals[tid]
	if not t then
		self:_write(jsonrpc.encode_response(id, {}))
		return
	end
	-- 关闭所有 pipe
	for _, pipe_name in ipairs({ "stdin", "stdout", "stderr" }) do
		local pipe = t[pipe_name]
		if pipe and not pipe:is_closing() then
			pcall(function()
				if pipe_name ~= "stdin" then
					pipe:read_stop()
				end
				pipe:close()
			end)
		end
	end
	-- 杀进程（如果还活着）
	if t.handle and not t.handle:is_closing() then
		pcall(function()
			t.handle:kill("sigterm")
		end)
	end
	self._terminals[tid] = nil
	self:_write(jsonrpc.encode_response(id, {}))
end

--- 处理 agent 发来的 notification
function Client:_handle_notification(msg)
	if msg.method == "session/update" and self.on_update then
		self.on_update(msg.params)
	end
end

--- 把 env table 转成 {"KEY=VALUE", ...} 列表（vim.uv.spawn 要求）
function Client:_env_list()
	local env = self.adapter.env or {}
	local list = {}
	for k, v in pairs(env) do
		list[#list + 1] = k .. "=" .. tostring(v)
	end
	return list
end

--- 从 content block 提取可渲染文本（对齐 codecompanion get_renderable_text）
function Client.get_renderable_text(block)
	if not block or type(block) ~= "table" then
		return nil
	end
	if block.type == "text" and type(block.text) == "string" then
		return block.text
	end
	if block.type == "resource_link" and type(block.uri) == "string" then
		return ("[resource: %s]"):format(block.uri)
	end
	if block.type == "resource" and block.resource then
		local r = block.resource
		if type(r.text) == "string" then
			return r.text
		end
		if type(r.uri) == "string" then
			return ("[resource: %s]"):format(r.uri)
		end
	end
	if block.type == "image" then
		return "[image]"
	end
	if block.type == "audio" then
		return "[audio]"
	end
	return nil
end

local M = {}
M.Client = Client

function M.new(adapter_config)
	return Client.new(adapter_config)
end

return M
