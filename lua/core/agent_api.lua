--- Structured RPC API for AI agents controlling nvim via --server
--- Every exported function is pcall-wrapped and returns JSON string: {ok:bool, data?, error?}
local M = {}

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

--- Spawn a Claude CLI terminal in nvim
--- args: {api?, mode?, args?}
---   api: 1 or 2 (default 1) - which CLAUDE_API config to use
---   mode: "v"=vsplit, "h"=hsplit, "t"=tab, "f"=float (default "t")
---   args: string - raw CLI args passed to claude command (e.g., "-p 'review this'")
local function spawn_claude(args)
	local s, e = pcall(function()
		if type(args) ~= "table" then
			args = {}
		end

		local api_num = args.api or 1
		local mode = args.mode or "t"
		local cli_args = args.args or ""

		-- Load API config
		local env_mod = require("core.env")
		local base_url = env_mod.get("CLAUDE_API" .. api_num .. "_BASE_URL")
		local token = env_mod.get("CLAUDE_API" .. api_num .. "_TOKEN")

		if not base_url or not token then
			return err("CLAUDE_API" .. api_num .. " config not found in .env")
		end

		-- Build command: env vars + claude + raw CLI args
		local cmd = string.format(
			"ANTHROPIC_BASE_URL=%s ANTHROPIC_AUTH_TOKEN=%s claude %s",
			base_url,
			token,
			cli_args
		)

		-- Terminal env (PATH setup)
		local term_env = vim.fn.environ()
		term_env.PATH = vim.fn.expand("$HOME/.local/bin")
			.. ":"
			.. vim.fn.expand("$HOME/.nvm/versions/node/v22.12.0/bin")
			.. ":"
			.. (term_env.PATH or "")

		local name = "claude_agent_" .. os.time()
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

		vim.fn.termopen(cmd, { env = term_env })
		vim.cmd("startinsert")

		return ok({ name = name, api = api_num, mode = mode })
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
M.spawn_claude = wrap("spawn_claude", spawn_claude)

return M
