--- 文件系统监听：检测子 AI 任务完成，通知主 AI 终端
--- Dashboard：底部分屏显示实时任务状态
local M = {}

local uv = vim.uv or vim.loop
local watchers = {} -- {task_name -> fs_event handle}
local task_status = {} -- {task_name -> last known status}
local dashboard_buf = nil -- dashboard buffer
local dashboard_win = nil -- dashboard window
local dashboard_timer = nil -- 刷新定时器

--- 获取任务基础目录
local function get_base_dir()
	local api = package.loaded["core.agent_api"]
	if api then
		return api._task_base_dir
	end
	return vim.fn.expand("~/.ai-tasks/" .. vim.fn.getpid())
end

--- 写调试日志（复用 agent_api 的日志文件）
local function log(level, msg)
	local base = get_base_dir()
	vim.fn.mkdir(base, "p")
	local f = io.open(base .. "/debug.log", "a")
	if not f then
		return
	end
	f:write(string.format("%s [%s] watcher: %s\n", os.date("!%Y-%m-%dT%H:%M:%SZ"), level, msg))
	f:close()
end

--- 获取 task→agent 映射
local function get_agent_for_task(task_name)
	local api = package.loaded["core.agent_api"]
	if api and api._task_agents and api._task_agents[task_name] then
		return api._task_agents[task_name]
	end
	return "?"
end

--- 构建任务状态行列表（dashboard 和通知共用）
local function collect_task_info()
	local base = get_base_dir()
	local dirs = vim.fn.glob(base .. "/*", false, true)
	local tasks = {}

	for _, dir in ipairs(dirs) do
		if vim.fn.isdirectory(dir) ~= 1 then
			goto continue
		end
		local name = vim.fn.fnamemodify(dir, ":t")
		local f = io.open(dir .. "/status", "r")
		local status = f and f:read("*a") or "unknown"
		if f then
			f:close()
		end
		status = vim.trim(status)
		local agent = get_agent_for_task(name)
		local has_result = vim.fn.filereadable(dir .. "/result.md") == 1

		tasks[#tasks + 1] = {
			name = name,
			status = status,
			agent = agent,
			has_result = has_result,
			dir = dir,
		}
		::continue::
	end

	return tasks
end

--- 构建通知文本
local function build_summary()
	local tasks = collect_task_info()
	if #tasks == 0 then
		return nil
	end

	local total = #tasks
	local completed = 0
	local lines = {}

	for _, t in ipairs(tasks) do
		if t.status == "done" or t.status == "error" then
			completed = completed + 1
		end
		local suffix = ""
		if t.status == "done" or t.status == "error" then
			suffix = " → " .. t.dir .. "/result.md"
		end
		lines[#lines + 1] = "  " .. t.name .. " (" .. t.agent .. "): " .. t.status .. suffix
	end

	if completed == 0 then
		return nil
	end

	return "[AI-TASKS] " .. completed .. "/" .. total .. " completed\n" .. table.concat(lines, "\n") .. "\n"
end

--- 往主 AI 终端注入通知
local function deliver_notification()
	local summary = build_summary()
	if not summary then
		return
	end

	log("INFO", "delivering notification:\n" .. summary)

	local api = package.loaded["core.agent_api"]

	-- 往主 AI 终端输入框打字（不带回车，由人决定是否提交）
	if api and api._get_main_terminal_bufnr then
		local main_bufnr = api._get_main_terminal_bufnr()
		log("DEBUG", "deliver: main_bufnr=" .. tostring(main_bufnr))
		if main_bufnr and vim.api.nvim_buf_is_valid(main_bufnr) then
			-- 找到主终端的 job_id
			local job_id = vim.b[main_bufnr].terminal_job_id
			log("DEBUG", "deliver: job_id=" .. tostring(job_id))
			if job_id then
				-- 不带 \r，文字出现在输入框但不提交
				vim.fn.chansend(job_id, summary .. "\r")
				log("INFO", "notification injected to main terminal bufnr=" .. main_bufnr)
			else
				log("WARN", "main terminal has no job_id, bufnr=" .. main_bufnr)
			end
		else
			log("WARN", "main terminal bufnr invalid or not detected: main_bufnr=" .. tostring(main_bufnr))
		end
	else
		log("WARN", "deliver: api not loaded or _get_main_terminal_bufnr missing")
	end

	-- vim.notify 保底（已禁用，避免打断输入）
	-- vim.notify(summary, vim.log.levels.INFO, { title = "AI Tasks" })

	-- 刷新 dashboard
	M.refresh_dashboard()
end

--- ============ Dashboard ============

--- 构建 dashboard 显示内容
local function build_dashboard_lines()
	local lines = {}
	lines[#lines + 1] = "╔══════════════════════════════════════════════╗"
	lines[#lines + 1] = "║           AI Task Dashboard                  ║"
	lines[#lines + 1] = "╠══════════════════════════════════════════════╣"

	-- Worker 状态
	local api = package.loaded["core.agent_api"]
	if api and api._spawned_terminals then
		local has_workers = false
		for name, info in pairs(api._spawned_terminals) do
			has_workers = true
			local status_icon = info.alive and "●" or "○"
			local cmd_short = info.cmd:match("([%w_-]+)") or info.cmd
			lines[#lines + 1] = string.format("║ %s %-10s  cmd=%-12s  buf=%d", status_icon, name, cmd_short, info.bufnr)
		end
		if not has_workers then
			lines[#lines + 1] = "║ (no workers)"
		end
	else
		lines[#lines + 1] = "║ (agent_api not loaded)"
	end

	lines[#lines + 1] = "╠══════════════════════════════════════════════╣"

	-- 任务状态
	local tasks = collect_task_info()
	if #tasks == 0 then
		lines[#lines + 1] = "║ (no tasks)"
	else
		local done_count = 0
		local total = #tasks
		for _, t in ipairs(tasks) do
			local icon = ({ pending = "◻", running = "▶", done = "✓", error = "✗" })[t.status] or "?"
			local result_hint = ""
			if t.has_result then
				result_hint = " [result]"
			end
			lines[#lines + 1] = string.format(
				"║ %s %-20s  agent=%-8s  %s%s",
				icon,
				t.name,
				t.agent,
				t.status,
				result_hint
			)
			if t.status == "done" or t.status == "error" then
				done_count = done_count + 1
			end
		end
		lines[#lines + 1] = "╠══════════════════════════════════════════════╣"
		lines[#lines + 1] = string.format("║ Total: %d  Done: %d  Running: %d", total, done_count, total - done_count)
	end

	lines[#lines + 1] = "╚══════════════════════════════════════════════╝"
	lines[#lines + 1] = " q=close  r=refresh  R=read result under cursor"

	return lines
end

--- 刷新 dashboard buffer 内容
function M.refresh_dashboard()
	if not dashboard_buf or not vim.api.nvim_buf_is_valid(dashboard_buf) then
		return
	end
	local lines = build_dashboard_lines()
	vim.bo[dashboard_buf].modifiable = true
	vim.api.nvim_buf_set_lines(dashboard_buf, 0, -1, false, lines)
	vim.bo[dashboard_buf].modifiable = false
end

--- 打开 dashboard（底部分屏）
function M.open_dashboard()
	-- 已经打开了就刷新
	if dashboard_win and vim.api.nvim_win_is_valid(dashboard_win) then
		M.refresh_dashboard()
		vim.api.nvim_set_current_win(dashboard_win)
		return
	end

	-- 创建 buffer
	dashboard_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[dashboard_buf].buftype = "nofile"
	vim.bo[dashboard_buf].bufhidden = "wipe"
	vim.bo[dashboard_buf].swapfile = false
	vim.api.nvim_buf_set_name(dashboard_buf, "[AI-Tasks]")

	-- 底部分屏
	vim.cmd("botright 12split")
	dashboard_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(dashboard_win, dashboard_buf)

	-- 窗口设置
	vim.wo[dashboard_win].number = false
	vim.wo[dashboard_win].relativenumber = false
	vim.wo[dashboard_win].signcolumn = "no"
	vim.wo[dashboard_win].cursorline = true
	vim.wo[dashboard_win].winfixheight = true

	-- 填充内容
	M.refresh_dashboard()

	-- 快捷键
	local opts = { buffer = dashboard_buf, nowait = true, silent = true }
	vim.keymap.set("n", "q", function()
		M.close_dashboard()
	end, opts)
	vim.keymap.set("n", "r", function()
		M.refresh_dashboard()
	end, opts)
	vim.keymap.set("n", "R", function()
		-- 读取光标所在行的任务 result
		local line = vim.api.nvim_get_current_line()
		local task_name = line:match("║%s+[%S]+%s+(%S+)")
		if task_name then
			local api = package.loaded["core.agent_api"]
			if api then
				local result = api.get_task_result({ name = task_name })
				vim.notify(result, vim.log.levels.INFO, { title = task_name })
			end
		end
	end, opts)

	-- 自动刷新定时器（每 3 秒）
	if dashboard_timer then
		dashboard_timer:stop()
	end
	dashboard_timer = uv.new_timer()
	dashboard_timer:start(
		3000,
		3000,
		vim.schedule_wrap(function()
			if dashboard_win and vim.api.nvim_win_is_valid(dashboard_win) then
				M.refresh_dashboard()
			else
				-- 窗口关了，停止定时器
				if dashboard_timer then
					dashboard_timer:stop()
					dashboard_timer:close()
					dashboard_timer = nil
				end
			end
		end)
	)
end

--- 关闭 dashboard
function M.close_dashboard()
	if dashboard_timer then
		dashboard_timer:stop()
		dashboard_timer:close()
		dashboard_timer = nil
	end
	if dashboard_win and vim.api.nvim_win_is_valid(dashboard_win) then
		vim.api.nvim_win_close(dashboard_win, true)
	end
	dashboard_win = nil
	dashboard_buf = nil
end

--- 切换 dashboard
function M.toggle_dashboard()
	if dashboard_win and vim.api.nvim_win_is_valid(dashboard_win) then
		M.close_dashboard()
	else
		M.open_dashboard()
	end
end

--- ============ Watcher ============

--- 监听单个任务的 status 文件变化
function M.watch_task(task_name)
	if watchers[task_name] then
		log("INFO", "watch_task: already watching " .. task_name)
		return
	end

	local base = get_base_dir()
	local status_path = base .. "/" .. task_name .. "/status"

	if vim.fn.filereadable(status_path) ~= 1 then
		log("WARN", "watch_task: status file not found: " .. status_path)
		return
	end

	local handle = uv.new_fs_event()
	if not handle then
		log("ERROR", "watch_task: failed to create fs_event for " .. task_name)
		return
	end

	handle:start(status_path, {}, function(watch_err, _, _)
		if watch_err then
			log("ERROR", "fs_event error for " .. task_name .. ": " .. watch_err)
			return
		end

		vim.schedule(function()
			local f = io.open(status_path, "r")
			if not f then
				log("WARN", "fs_event: cannot read " .. status_path)
				return
			end
			local new_status = vim.trim(f:read("*a"))
			f:close()

			local old_status = task_status[task_name]
			if new_status == old_status then
				return
			end

			log("INFO", task_name .. ": " .. (old_status or "nil") .. " → " .. new_status)
			task_status[task_name] = new_status

			-- 刷新 dashboard
			M.refresh_dashboard()

			if new_status == "done" or new_status == "error" then
				deliver_notification()
			end
		end)
	end)

	watchers[task_name] = handle
	task_status[task_name] = "pending"
	log("INFO", "watch_task: started watching " .. task_name .. " at " .. status_path)
end

--- 停止所有监听
function M.stop_all()
	log("INFO", "stop_all: closing " .. vim.tbl_count(watchers) .. " watchers")
	for name, handle in pairs(watchers) do
		if not handle:is_closing() then
			handle:stop()
			handle:close()
		end
		watchers[name] = nil
	end
	task_status = {}
end

--- 归档目录
local archive_dir = vim.fn.expand("~/.ai-tasks/archive")

--- 清理：任务目录归档到 archive，然后删掉 pid 目录
local function cleanup()
	log("INFO", "cleanup: VimLeavePre triggered")
	M.close_dashboard()
	M.stop_all()
	local base = get_base_dir()
	if vim.fn.isdirectory(base) ~= 1 then
		return
	end
	vim.fn.mkdir(archive_dir, "p")
	local ts = os.date("!%Y%m%d-%H%M%S")
	local dirs = vim.fn.glob(base .. "/*", false, true)
	for _, dir in ipairs(dirs) do
		if vim.fn.isdirectory(dir) == 1 then
			local name = vim.fn.fnamemodify(dir, ":t")
			local dest = archive_dir .. "/" .. name .. "-" .. ts
			vim.fn.rename(dir, dest)
		end
	end
	-- 删掉 pid 目录（剩下的只有 debug.log 之类的文件）
	vim.fn.delete(base, "rf")
	log("INFO", "cleanup: archived tasks, removed " .. base)
end

function M.setup()
	local base = get_base_dir()
	local dirs = vim.fn.glob(base .. "/*", false, true)
	for _, dir in ipairs(dirs) do
		if vim.fn.isdirectory(dir) ~= 1 then
			goto continue
		end
		local name = vim.fn.fnamemodify(dir, ":t")
		M.watch_task(name)
		::continue::
	end

	vim.api.nvim_create_autocmd("VimLeavePre", {
		callback = cleanup,
		desc = "Clean up ai-tasks directory",
	})

	-- 注册命令
	vim.api.nvim_create_user_command("AITasks", function()
		M.toggle_dashboard()
	end, { desc = "Toggle AI Task Dashboard" })

	log("INFO", "setup: task_watcher initialized, base=" .. base)
end

return M
