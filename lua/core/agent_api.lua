--- Structured RPC API for AI agents controlling nvim via --server
--- Every exported function is pcall-wrapped and returns JSON string: {ok:bool, data?, error?}
local M = {}
local terminal = require("core.terminal")

local json_encode = vim.fn.json_encode

local function json(data)
	return json_encode(data)
end

local function ok(data)
	return json({ ok = true, data = data })
end

local function err(msg)
	return json({ ok = false, error = msg })
end

--- Append a log line to NVIM_AGENT_LOG_FILE
--- Format: timestamp \t event=agent_api \t func=name \t ok=bool \t args_summary
local function log_call(func_name, call_ok, args_summary)
	local log_file = vim.env.NVIM_AGENT_LOG_FILE
	if not log_file or log_file == "" then
		return
	end
	local f = io.open(log_file, "a")
	if not f then
		return
	end
	f:write(table.concat({
		os.date("!%Y-%m-%dT%H:%M:%SZ"),
		"event=agent_api",
		"func=" .. func_name,
		"ok=" .. tostring(call_ok),
		"args=" .. (args_summary or ""),
	}, "\t") .. "\n")
	f:close()
end

--- Wrap an API function with logging
local function wrap(func_name, fn)
	return function(args)
		local result = fn(args)
		-- peek into result to determine ok status
		local call_ok = result and result:find('"ok":true', 1, true) and true or false
		-- summarize args for log
		local summary = ""
		if type(args) == "string" then
			summary = args:sub(1, 80)
		elseif type(args) == "table" then
			local s, encoded = pcall(json_encode, args)
			if s then
				summary = encoded:sub(1, 80)
			end
		end
		log_call(func_name, call_ok, summary)
		return result
	end
end

--- Find the first non-terminal, non-floating editor window
local function find_editor_win()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local cfg = vim.api.nvim_win_get_config(win)
		if cfg.relative == "" then
			local buf = vim.api.nvim_win_get_buf(win)
			if vim.bo[buf].buftype ~= "terminal" then
				return win
			end
		end
	end
	return nil
end

--- Open file in editor window, optional line/col jump
--- args: [path, line?, col?] or "path:line:col" string
local function open_file(args)
	local s, e = pcall(function()
		local path, line, col

		-- Support both array and string formats
		if type(args) == "string" then
			local parts = vim.split(args, ":", { plain = true })
			path = parts[1]
			line = tonumber(parts[2])
			col = tonumber(parts[3])
		elseif type(args) == "table" and #args >= 1 then
			path = args[1]
			line = args[2]
			col = args[3]
		else
			return err("args must be [path, line?, col?] or 'path:line:col'")
		end

		path = vim.fn.fnamemodify(path, ":p")

		local win = find_editor_win()
		if not win then
			return err("no editor window found")
		end

		vim.api.nvim_set_current_win(win)
		vim.cmd("edit " .. vim.fn.fnameescape(path))

		if line then
			local lnum = math.max(1, math.min(line, vim.api.nvim_buf_line_count(0)))
			local c = col and math.max(0, col - 1) or 0
			vim.api.nvim_win_set_cursor(win, { lnum, c })
			vim.cmd("normal! zz")
		end

		return ok({ file = path, line = line, col = col })
	end)
	if not s then
		return err(tostring(e))
	end
	return e
end

--- Return a context snapshot: cwd, windows, mode, lsp clients
local function get_context()
	local s, e = pcall(function()
		local wins = {}
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
			local buf = vim.api.nvim_win_get_buf(win)
			local cfg = vim.api.nvim_win_get_config(win)
			wins[#wins + 1] = {
				win = win,
				buf = buf,
				name = vim.api.nvim_buf_get_name(buf),
				buftype = vim.bo[buf].buftype,
				filetype = vim.bo[buf].filetype,
				modified = vim.bo[buf].modified,
				floating = cfg.relative ~= "",
			}
		end

		local clients = {}
		for _, c in ipairs(vim.lsp.get_clients()) do
			clients[#clients + 1] = { id = c.id, name = c.name }
		end

		return ok({
			cwd = vim.fn.getcwd(),
			mode = vim.api.nvim_get_mode().mode,
			wins = wins,
			lsp_clients = clients,
			current_win = vim.api.nvim_get_current_win(),
			current_buf = vim.api.nvim_get_current_buf(),
			current_file = vim.api.nvim_buf_get_name(0),
		})
	end)
	if not s then
		return err(tostring(e))
	end
	return e
end

--- List all loaded buffers
local function get_buffers()
	local s, e = pcall(function()
		local bufs = {}
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(buf) then
				bufs[#bufs + 1] = {
					bufnr = buf,
					name = vim.api.nvim_buf_get_name(buf),
					filetype = vim.bo[buf].filetype,
					buftype = vim.bo[buf].buftype,
					modified = vim.bo[buf].modified,
					line_count = vim.api.nvim_buf_line_count(buf),
				}
			end
		end
		return ok(bufs)
	end)
	if not s then
		return err(tostring(e))
	end
	return e
end

--- Get LSP diagnostics
local function get_diagnostics(args)
	local s, e = pcall(function()
		local opts = {}
		if type(args) == "table" then
			if args.bufnr then
				opts.bufnr = args.bufnr
			end
			if args.severity then
				opts.severity = args.severity
			end
		end

		local diags = vim.diagnostic.get(opts.bufnr, { severity = opts.severity })
		local result = {}
		for _, d in ipairs(diags) do
			result[#result + 1] = {
				bufnr = d.bufnr,
				file = vim.api.nvim_buf_get_name(d.bufnr),
				lnum = d.lnum + 1,
				col = d.col + 1,
				severity = d.severity,
				message = d.message,
				source = d.source,
				code = d.code,
			}
		end
		return ok(result)
	end)
	if not s then
		return err(tostring(e))
	end
	return e
end

--- Execute arbitrary lua code string
local function exec_lua(code)
	local s, e = pcall(function()
		if type(code) ~= "string" then
			return err("code must be a string")
		end
		local fn, load_err = load(code)
		if not fn then
			return err("load error: " .. tostring(load_err))
		end
		local run_ok, result = pcall(fn)
		if not run_ok then
			return err("runtime error: " .. tostring(result))
		end
		if result == nil then
			return ok(vim.NIL)
		end
		return ok(result)
	end)
	if not s then
		return err(tostring(e))
	end
	return e
end

--- Send a notification
local function notify(args)
	local s, e = pcall(function()
		local msg, level
		if type(args) == "string" then
			msg = args
			level = vim.log.levels.INFO
		elseif type(args) == "table" then
			msg = args[1] or ""
			level = args[2] or vim.log.levels.INFO
		else
			return err("args must be string or [msg, level?]")
		end
		vim.notify(msg, level, { title = "Agent" })
		return ok({ msg = msg, level = level })
	end)
	if not s then
		return err(tostring(e))
	end
	return e
end

--- 任务基础目录：~/.ai-tasks/{nvim-pid}/
local task_base_dir = vim.fn.expand("~/.ai-tasks/" .. vim.fn.getpid())

--- 确保目录存在
local function ensure_dir(dir)
	vim.fn.mkdir(dir, "p")
end

--- task 系统调试日志 → ~/.ai-tasks/{pid}/debug.log
local function task_log(level, source, msg)
	ensure_dir(task_base_dir)
	local f = io.open(task_base_dir .. "/debug.log", "a")
	if not f then
		return
	end
	f:write(string.format("%s [%s] %s: %s\n", os.date("!%Y-%m-%dT%H:%M:%SZ"), level, source, msg))
	f:close()
end

--- 写文件（同步）
local function write_file(path, content)
	local f = io.open(path, "w")
	if not f then
		return false
	end
	f:write(content)
	f:close()
	return true
end

--- 读文件（同步）
local function read_file(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()
	return content
end

--- Spawn a CLI terminal in nvim and track it
--- args: {cmd, mode?, name?}
---   cmd: string - full shell command to run (e.g., "claude --model sonnet", "gemini", "codex")
---   mode: "t"=tab(default), "v"=vsplit, "h"=hsplit, "f"=float
---   name: optional label for tracking
local spawned_terminals = {} -- {name -> {bufnr, job_id, cmd, alive}}
local task_agents = {} -- {task_name -> agent_name}
local main_terminal_bufnr = nil -- 主 AI 终端 bufnr，由调用方传入

local function spawn_cli(args)
	local s, e = pcall(function()
		if type(args) == "string" then
			args = { cmd = args }
		end
		if type(args) ~= "table" or not args.cmd then
			return err("args must be {cmd, mode?, name?} or a command string")
		end

		local cmd = args.cmd
		local mode = args.mode or "v"
		local name = args.name or ("cli_" .. os.time())

		-- 快速模式闭环：传了 task 就自动创建任务目录，并把回写指令注入 cmd
		local task_dir_for_quick
		if args.task then
			local task_name = type(args.task) == "table" and args.task.name or name
			local task_desc = type(args.task) == "table" and args.task.description or tostring(args.task)
			local td = task_base_dir .. "/" .. task_name
			ensure_dir(td)
			write_file(td .. "/status", "pending")
			-- 通知 watcher
			local watcher = package.loaded["core.task_watcher"]
			if watcher and watcher.watch_task then
				watcher.watch_task(task_name)
			end
			task_dir_for_quick = td
			task_agents[task_name] = name
			task_log("INFO", "spawn_cli", "quick task created: " .. task_name)

			-- 把完整指令写到 task.md（任务描述 + 永久回写规则），cmd 改为读 task.md
			local full_instructions = task_desc
				.. "\n\n## 永久规则（每次收到新任务都必须遵守）\n"
				.. "每次完成任务后必须执行以下两步:\n"
				.. "1. 把执行结果写到 "
				.. td
				.. "/result.md\n"
				.. "2. 执行: echo done > "
				.. td
				.. "/status\n"
				.. "后续通过终端收到的新任务也一样，完成后都要执行这两步。"
			write_file(td .. "/task.md", full_instructions)

			-- 提取 cmd 中的 CLI 前缀（去掉末尾引号包裹的任务描述）
			local cli_prefix = cmd:match('^(.-)%s*"[^"]*"%s*$')
				or cmd:match("^(.-)%s*'[^']*'%s*$")
				or cmd
			cmd = cli_prefix .. ' "请阅读并执行任务: cat ' .. td .. '/task.md"'
		end

		-- 记录主 AI 终端 bufnr（优先用 caller_bufnr，兜底读环境变量）
		if not main_terminal_bufnr then
			local raw = args.caller_bufnr or vim.env.NVIM_TERMINAL_BUFNR
			task_log("DEBUG", "spawn_cli", "caller_bufnr raw=" .. tostring(raw) .. " env=" .. tostring(vim.env.NVIM_TERMINAL_BUFNR))
			local bufnr = tonumber(raw)
			if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
				main_terminal_bufnr = bufnr
				task_log("INFO", "spawn_cli", "main terminal registered: bufnr=" .. bufnr)
			else
				task_log("WARN", "spawn_cli", "main terminal NOT registered: raw=" .. tostring(raw) .. " tonumber=" .. tostring(bufnr) .. " valid=" .. tostring(bufnr and vim.api.nvim_buf_is_valid(bufnr)))
			end
		else
			task_log("DEBUG", "spawn_cli", "main terminal already registered: bufnr=" .. main_terminal_bufnr)
		end

		local buf, win

		if mode == "t" then
			vim.cmd("tabnew")
			buf = vim.api.nvim_get_current_buf()
		elseif mode == "h" then
			vim.cmd("botright 15split")
			win = vim.api.nvim_get_current_win()
			buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_win_set_buf(win, buf)
		elseif mode == "f" then
			buf = vim.api.nvim_create_buf(false, true)
			local width = math.floor(vim.o.columns * 0.8)
			local height = math.floor(vim.o.lines * 0.8)
			win = vim.api.nvim_open_win(buf, true, {
				relative = "editor",
				width = width,
				height = height,
				row = math.floor((vim.o.lines - height) / 2),
				col = math.floor((vim.o.columns - width) / 2),
				style = "minimal",
				border = "rounded",
				title = " " .. name .. " ",
				title_pos = "center",
			})
		else -- "v" vsplit
			local width = math.floor(vim.o.columns * 0.4)
			vim.cmd("botright " .. width .. "vsplit")
			win = vim.api.nvim_get_current_win()
			buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_win_set_buf(win, buf)
		end

		-- 每个终端都带上自己的 bufnr 环境变量
		local spec = terminal.normalize_spec({
			cmd = cmd,
			env = { NVIM_TERMINAL_BUFNR = tostring(buf) },
		})

		local job_id = terminal.termopen_shell(spec, {
			on_exit = function(_, exit_code)
				if spawned_terminals[name] then
					spawned_terminals[name].alive = false
					spawned_terminals[name].exit_code = exit_code
				end
			end,
		})
		vim.cmd("startinsert")

		spawned_terminals[name] = {
			bufnr = buf,
			job_id = job_id,
			cmd = cmd,
			alive = true,
		}

		return ok({ name = name, bufnr = buf, job_id = job_id, mode = mode })
	end)
	if not s then
		return err(tostring(e))
	end
	return e
end

--- Read terminal buffer output
--- args: {bufnr} or {name} or {bufnr, tail?}
---   bufnr: buffer number to read
---   name: spawned terminal name (from spawn_cli)
---   tail: number of lines from end (default: all)
local function get_terminal_output(args)
	local s, e = pcall(function()
		if type(args) ~= "table" then
			return err("args must be {bufnr} or {name} or {bufnr, tail?}")
		end

		local bufnr = args.bufnr
		local name = args.name
		local tail = args.tail

		-- Resolve bufnr from name
		if not bufnr and name and spawned_terminals[name] then
			bufnr = spawned_terminals[name].bufnr
		end

		if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
			return err("invalid or missing bufnr")
		end

		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

		-- Strip trailing empty lines (terminal buffers pad with blanks)
		while #lines > 0 and lines[#lines] == "" do
			lines[#lines] = nil
		end

		if tail and tail > 0 and #lines > tail then
			local start = #lines - tail + 1
			local result = {}
			for i = start, #lines do
				result[#result + 1] = lines[i]
			end
			lines = result
		end

		local info = spawned_terminals[name]
		return ok({
			bufnr = bufnr,
			lines = lines,
			line_count = #lines,
			alive = info and info.alive or nil,
			exit_code = info and info.exit_code or nil,
		})
	end)
	if not s then
		return err(tostring(e))
	end
	return e
end

--- List all spawned terminals and their status
local function list_terminals()
	local s, e = pcall(function()
		local result = {}
		for name, info in pairs(spawned_terminals) do
			local valid = vim.api.nvim_buf_is_valid(info.bufnr)
			result[#result + 1] = {
				name = name,
				bufnr = info.bufnr,
				cmd = info.cmd,
				alive = info.alive and valid,
				exit_code = info.exit_code,
			}
		end
		return ok(result)
	end)
	if not s then
		return err(tostring(e))
	end
	return e
end

--- 判断 cmd 是否为 claude CLI（claude/c1/c2 等）
local function is_claude_cli(cmd)
	local first = cmd:match("^(%S+)")
	return first == "claude" or first == "c1" or first == "c2"
end

--- Send text input to a terminal buffer
--- args: {bufnr?, name?, text, task?, submit?}
---   task=true 时自动重置 status 为 pending，重新激活 watcher
local function send_to_terminal(args)
	local s, e = pcall(function()
		if type(args) ~= "table" or not args.text then
			return err("args must be {bufnr?, name?, text}")
		end

		local bufnr = args.bufnr
		local name = args.name

		if not bufnr and name and spawned_terminals[name] then
			bufnr = spawned_terminals[name].bufnr
		end

		local info
		for _, v in pairs(spawned_terminals) do
			if v.bufnr == bufnr then
				info = v
				break
			end
		end

		if not info or not info.alive then
			return err("terminal not alive")
		end

		-- task 模式：重置 status + 重新激活 watcher
		if args.task and name then
			local task_name = task_agents[name] and name or name
			-- 反查 task_name：从 task_agents 里找这个 agent 对应的任务
			for tn, an in pairs(task_agents) do
				if an == name then
					task_name = tn
					break
				end
			end
			local td = task_base_dir .. "/" .. task_name
			if vim.fn.isdirectory(td) == 1 then
				write_file(td .. "/status", "pending")
				local watcher = package.loaded["core.task_watcher"]
				if watcher and watcher.watch_task then
					watcher.watch_task(task_name)
				end
				task_log("INFO", "send_to_terminal", "task reset: " .. task_name .. " → pending")
			end
		end

		local text = args.text
		-- task 模式：追加回写指令，防止子 AI 上下文遗忘
		if args.task and name then
			local task_name = task_agents[name] and name or name
			for tn, an in pairs(task_agents) do
				if an == name then
					task_name = tn
					break
				end
			end
			local td = task_base_dir .. "/" .. task_name
			if vim.fn.isdirectory(td) == 1 then
				text = text
					.. "\n\n完成后必须执行：1. 把结果写到 " .. td .. "/result.md"
					.. "  2. 执行: echo done > " .. td .. "/status"
			end
		end
		-- 默认自动加回车提交，除非 submit=false
		if args.submit ~= false and text:sub(-1) ~= "\r" then
			text = text .. "\r"
		end

		vim.fn.chansend(info.job_id, text)

		-- 非 claude CLI 额外发一次回车（某些 TUI 需要）
		if text:sub(-1) == "\r" and not is_claude_cli(info.cmd or "") then
			vim.defer_fn(function()
				if info.alive then
					vim.fn.chansend(info.job_id, "\r")
				end
			end, 500)
		end

		return ok({ sent = true })
	end)
	if not s then
		return err(tostring(e))
	end
	return e
end

--- 查询所有任务状态
local function list_tasks()
	local s, e = pcall(function()
		local result = {}
		local dirs = vim.fn.glob(task_base_dir .. "/*", false, true)
		for _, dir in ipairs(dirs) do
			-- 跳过非目录项（如 debug.log）
			if vim.fn.isdirectory(dir) ~= 1 then
				goto continue
			end
			local name = vim.fn.fnamemodify(dir, ":t")
			local status = read_file(dir .. "/status")
			local has_result = vim.fn.filereadable(dir .. "/result.md") == 1
			local created_at = vim.fn.getftime(dir .. "/task.md")
			result[#result + 1] = {
				name = name,
				status = status and vim.trim(status) or "unknown",
				has_result = has_result,
				created_at = created_at,
			}
			::continue::
		end
		return ok(result)
	end)
	if not s then
		return err(tostring(e))
	end
	return e
end

--- 读取任务结果
--- args: {name}
local function get_task_result(args)
	local s, e = pcall(function()
		if type(args) ~= "table" or not args.name then
			return err("args must be {name}")
		end

		local result_path = task_base_dir .. "/" .. args.name .. "/result.md"
		local content = read_file(result_path)
		if not content then
			return err("result not found for task: " .. args.name)
		end

		local status = read_file(task_base_dir .. "/" .. args.name .. "/status")
		return ok({
			name = args.name,
			status = status and vim.trim(status) or "unknown",
			result = content,
		})
	end)
	if not s then
		return err(tostring(e))
	end
	return e
end

M.open_file = wrap("open_file", open_file)
M.get_context = wrap("get_context", get_context)
M.get_buffers = wrap("get_buffers", get_buffers)
M.get_diagnostics = wrap("get_diagnostics", get_diagnostics)
M.exec_lua = wrap("exec_lua", exec_lua)
M.notify = wrap("notify", notify)
M.spawn_cli = wrap("spawn_cli", spawn_cli)
M.get_terminal_output = wrap("get_terminal_output", get_terminal_output)
M.list_terminals = wrap("list_terminals", list_terminals)
M.send_to_terminal = wrap("send_to_terminal", send_to_terminal)
M.list_tasks = wrap("list_tasks", list_tasks)
M.get_task_result = wrap("get_task_result", get_task_result)

--- 暴露给 task_watcher 用
M._spawned_terminals = spawned_terminals
M._task_base_dir = task_base_dir
M._task_agents = task_agents
M._get_main_terminal_bufnr = function()
	return main_terminal_bufnr
end

return M
