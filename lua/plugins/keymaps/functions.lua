-- ============================================================================
-- Keymap 回调函数集合
-- 所有复杂的回调函数集中在此，供 all.lua 引用
-- ============================================================================
local M = {}

-- ============================================================================
-- 辅助函数
-- ============================================================================
local function get_project_root()
	local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null")
	if git_root ~= "" then
		return git_root:gsub("%s+", "")
	end
	return nil
end

local function copy_to_clipboard(content, notify_message)
	if not content or content == "" then
		vim.notify("没有内容可复制", vim.log.levels.WARN)
		return
	end
	if os.getenv('SSH_CLIENT') or os.getenv('SSH_TTY') then
		local text = content:gsub('\n$', '')
		local osc52 = string.format('\027]52;c;%s\007', vim.base64.encode(text))
		io.stdout:write(osc52)
		io.stdout:flush()
		vim.notify("已通过OSC52" .. notify_message, vim.log.levels.INFO)
	else
		vim.fn.setreg('+', content)
		vim.notify("已" .. notify_message, vim.log.levels.INFO)
	end
end

-- ============================================================================
-- Editor: Some Thing
-- ============================================================================
function M.create_new_file()
	local current_directory = vim.fn.expand("%:p:h")
	local directory = current_directory ~= "" and current_directory or get_project_root()
	if not directory then
		print("Error: No project root found.")
		return
	end
	vim.ui.input({
		prompt = "New File Name (in " .. directory .. "): ",
		default = directory .. "/",
	}, function(new_name)
		if not new_name or new_name == "" then return end
		local dir = new_name:match("(.*/)")
		if dir and not vim.loop.fs_stat(dir) then
			os.execute("mkdir -p " .. dir)
		end
		local file = io.open(new_name, "w")
		if file then
			file:close()
			vim.cmd("e " .. new_name)
			print("File created: " .. new_name)
		end
	end)
end

function M.rename_current_file()
	local old_path = vim.fn.expand("%:p")
	local default_input = old_path
	vim.ui.input({
		prompt = "New Path and Name: ",
		default = default_input,
	}, function(new_path)
		if not new_path or new_path == "" then return end
		local dir = new_path:match("(.*/)")
		if dir and not vim.loop.fs_stat(dir) then
			os.execute("mkdir -p " .. dir)
		end
		local success, err = os.rename(old_path, new_path)
		if success then
			vim.cmd("e " .. new_path)
			print("File renamed to " .. new_path)
		else
			print("Error renaming file: " .. err)
		end
	end)
end

function M.open_project_in_new_tab()
	local input = vim.fn.input("Tab Name: ")
	if input ~= "" then
		vim.cmd("tabnew")
		vim.cmd("Telescope projects")
		vim.cmd("LualineRenameTab " .. input)
	end
end

function M.toggle_neovide()
	vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen
end

function M.toggle_hlsearch()
	vim.o.hlsearch = not vim.o.hlsearch
end

function M.copy_message()
	copy_to_clipboard(vim.fn.getreg("+"), "复制消息内容到剪贴板")
end

function M.copy_last_message()
	local messages = vim.api.nvim_exec2("messages", {output = true})
	local lines = vim.split(messages.output, "\n")
	for i = #lines, 1, -1 do
		if lines[i] ~= "" then
			copy_to_clipboard(lines[i], "复制最后一条消息到剪贴板")
			return
		end
	end
end

function M.copy_all_messages()
	local messages = vim.api.nvim_exec2("messages", {output = true})
	copy_to_clipboard(messages.output, "复制所有消息到剪贴板")
end

function M.copy_file_path()
	local file_path = vim.fn.expand('%:p')
	copy_to_clipboard(file_path, "复制文件路径到剪贴板: " .. file_path)
end

function M.copy_word_with_location()
	local word = vim.fn.expand('<cword>')
	local file_path = vim.fn.expand('%:p')
	local line_num = vim.fn.line('.')
	local content = string.format("%s:%d:%s", file_path, line_num, word)
	copy_to_clipboard(content, "复制 word 和位置信息到剪贴板")
end

function M.copy_selection_with_location()
	local mode = vim.fn.mode()
	local start_line, end_line
	local is_visual = false

	if mode == 'v' or mode == 'V' or mode == '\22' then
		-- Visual mode
		is_visual = true
		start_line = vim.fn.line('v')
		end_line = vim.fn.line('.')
		if start_line > end_line then
			start_line, end_line = end_line, start_line
		end
	else
		-- Normal mode - use current line
		start_line = vim.fn.line('.')
		end_line = start_line
	end

	local file_path = vim.fn.expand('%:p')
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	local selected_text = table.concat(lines, '\n')

	local location_info
	if start_line == end_line then
		location_info = string.format("%s:%d", file_path, start_line)
	else
		location_info = string.format("%s:%d-%d", file_path, start_line, end_line)
	end

	local content = string.format("%s\n\n%s", location_info, selected_text)

	-- 退出 visual 模式
	if is_visual then
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
	end

	copy_to_clipboard(content, "复制内容和位置信息到剪贴板")
end

function M.open_path_at_cursor()
	local current_line = vim.api.nvim_get_current_line()
	local cursor_col = vim.api.nvim_win_get_cursor(0)[2] + 1
	local patterns = { "[^%s:]+:%d+:%d+", "[^%s:]+:%d+" }
	local match = nil
	for _, pattern in ipairs(patterns) do
		local start_col = 1
		while true do
			local s, e = current_line:find(pattern, start_col)
			if not s then break end
			if cursor_col >= s and cursor_col <= e then
				match = current_line:sub(s, e)
				break
			end
			start_col = e + 1
		end
		if match then break end
	end
	if not match then
		vim.notify("未在光标附近找到 path:line", vim.log.levels.WARN)
		return
	end
	match = match:gsub("[,.;]+$", "")
	local path_part, line_str, col_str = match:match("^([^:]+):(%d+):?(%d*)$")
	if not path_part then
		vim.notify("无法解析路径: " .. match, vim.log.levels.WARN)
		return
	end
	-- Resolve path
	local target_path = path_part
	if path_part:sub(1, 1) == "~" then
		target_path = vim.fn.expand(path_part)
	elseif not path_part:match("^/") then
		local project_root = get_project_root()
		if project_root then
			local candidate = vim.fn.fnamemodify(project_root .. "/" .. path_part, ":p")
			if vim.fn.filereadable(candidate) == 1 then
				target_path = candidate
			end
		end
	end
	if vim.fn.filereadable(target_path) == 0 then
		vim.notify("文件不存在: " .. target_path, vim.log.levels.ERROR)
		return
	end
	vim.cmd("edit " .. vim.fn.fnameescape(target_path))
	local line_num = tonumber(line_str) or 1
	local col_num = tonumber(col_str)
	vim.api.nvim_win_set_cursor(0, { line_num, col_num and col_num - 1 or 0 })
end

function M.reload_config()
	local ok, reload = pcall(require, "core.reload")
	if ok then
		reload.reload_config()
	else
		vim.notify("无法加载 reload 模块", vim.log.levels.ERROR)
	end
end

-- ============================================================================
-- Editor: Terminal（原生 API 实现）
-- ============================================================================
local native_terminals = {}  -- { [name] = { buf = buf, win = win } }

local function build_claude_cmd(api_num)
	local env = require("core.env")
	local base_url = env.get("CLAUDE_API" .. api_num .. "_BASE_URL")
	local token = env.get("CLAUDE_API" .. api_num .. "_TOKEN")
	if base_url and token then
		return string.format("ANTHROPIC_BASE_URL=%s ANTHROPIC_AUTH_TOKEN=%s claude", base_url, token)
	end
	return "claude"
end

local function get_term_env()
	local env = vim.fn.environ()
	env.PATH = vim.fn.expand("$HOME/.local/bin") .. ":" .. vim.fn.expand("$HOME/.nvm/versions/node/v22.12.0/bin") .. ":" .. (env.PATH or "")
	return env
end

-- 创建浮动终端
local function create_float_term(name, cmd, opts)
	opts = opts or {}
	local width = opts.width or math.floor(vim.o.columns * 0.8)
	local height = opts.height or math.floor(vim.o.lines * 0.8)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = opts.title or (" " .. name .. " "),
		title_pos = "center",
	})

	vim.fn.termopen(cmd, {
		env = get_term_env(),
		on_exit = function()
			native_terminals[name] = nil
		end,
	})

	native_terminals[name] = { buf = buf, win = win, type = "float" }
	vim.cmd("startinsert")

	-- q 关闭
	vim.keymap.set("n", "q", function()
		if native_terminals[name] and native_terminals[name].win and vim.api.nvim_win_is_valid(native_terminals[name].win) then
			vim.api.nvim_win_close(native_terminals[name].win, true)
			native_terminals[name].win = nil
		end
	end, { buffer = buf, noremap = true, silent = true })
end

-- 创建水平分割终端
local function create_horizontal_term(name, cmd, opts)
	opts = opts or {}
	local height = opts.height or 15

	vim.cmd("botright " .. height .. "split")
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(win, buf)

	vim.fn.termopen(cmd, {
		env = get_term_env(),
		on_exit = function()
			native_terminals[name] = nil
		end,
	})

	native_terminals[name] = { buf = buf, win = win, type = "horizontal" }
	vim.cmd("startinsert")
end

-- 创建垂直分割终端
local function create_vertical_term(name, cmd, opts)
	opts = opts or {}
	local width = opts.width or math.floor(vim.o.columns * 0.4)

	vim.cmd("botright " .. width .. "vsplit")
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(win, buf)

	vim.fn.termopen(cmd, {
		env = get_term_env(),
		on_exit = function()
			native_terminals[name] = nil
		end,
	})

	native_terminals[name] = { buf = buf, win = win, type = "vertical" }
	vim.cmd("startinsert")
end

-- 创建 tab 终端
local function create_tab_term(name, cmd)
	vim.cmd("tabnew")
	local buf = vim.api.nvim_get_current_buf()

	vim.fn.termopen(cmd, {
		env = get_term_env(),
		on_exit = function()
			native_terminals[name] = nil
		end,
	})

	native_terminals[name] = { buf = buf, type = "tab" }
	vim.cmd("startinsert")
end

-- 通用终端 toggle
local function toggle_term(name, cmd, direction, opts)
	local state = native_terminals[name]

	-- 检查 buffer 是否有效
	if state and state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		-- 检查窗口是否存在
		if state.win and vim.api.nvim_win_is_valid(state.win) then
			-- 关闭窗口
			vim.api.nvim_win_close(state.win, true)
			native_terminals[name].win = nil
			return
		end

		-- 窗口不存在，重新打开
		if direction == "float" then
			opts = opts or {}
			local width = opts.width or math.floor(vim.o.columns * 0.8)
			local height = opts.height or math.floor(vim.o.lines * 0.8)
			local row = math.floor((vim.o.lines - height) / 2)
			local col = math.floor((vim.o.columns - width) / 2)

			local win = vim.api.nvim_open_win(state.buf, true, {
				relative = "editor",
				width = width,
				height = height,
				row = row,
				col = col,
				style = "minimal",
				border = "rounded",
				title = opts.title or (" " .. name .. " "),
				title_pos = "center",
			})
			native_terminals[name].win = win
			vim.cmd("startinsert")
		elseif direction == "horizontal" then
			opts = opts or {}
			local height = opts.height or 15
			vim.cmd("botright " .. height .. "split")
			local win = vim.api.nvim_get_current_win()
			vim.api.nvim_win_set_buf(win, state.buf)
			native_terminals[name].win = win
			vim.cmd("startinsert")
		elseif direction == "vertical" then
			opts = opts or {}
			local width = opts.width or math.floor(vim.o.columns * 0.4)
			vim.cmd("botright " .. width .. "vsplit")
			local win = vim.api.nvim_get_current_win()
			vim.api.nvim_win_set_buf(win, state.buf)
			native_terminals[name].win = win
			vim.cmd("startinsert")
		elseif direction == "tab" then
			-- 找到包含该 buffer 的 tab
			for _, tabnr in ipairs(vim.api.nvim_list_tabpages()) do
				local wins = vim.api.nvim_tabpage_list_wins(tabnr)
				for _, win in ipairs(wins) do
					if vim.api.nvim_win_get_buf(win) == state.buf then
						vim.api.nvim_set_current_tabpage(tabnr)
						vim.api.nvim_set_current_win(win)
						vim.cmd("startinsert")
						return
					end
				end
			end
			-- 没找到，新建 tab
			vim.cmd("tabnew")
			vim.api.nvim_win_set_buf(0, state.buf)
			vim.cmd("startinsert")
		end
		return
	end

	-- 创建新终端
	if direction == "float" then
		create_float_term(name, cmd, opts)
	elseif direction == "horizontal" then
		create_horizontal_term(name, cmd, opts)
	elseif direction == "vertical" then
		create_vertical_term(name, cmd, opts)
	elseif direction == "tab" then
		create_tab_term(name, cmd)
	end
end

-- 终端函数
function M.terminal_ncdu_toggle() toggle_term("ncdu", "ncdu --color dark", "float", { title = " Ncdu " }) end
function M.terminal_htop_toggle() toggle_term("htop", "htop", "float", { title = " Htop " }) end
function M.terminal_ipython_toggle() toggle_term("ipython", "ipython", "horizontal") end
function M.terminal_lua_toggle() toggle_term("lua", "lua", "horizontal") end
function M.terminal_newterm_toggle() toggle_term("newterm", vim.o.shell, "float", { title = " Terminal " }) end
function M.terminal_newsboat_toggle() toggle_term("newsboat", "newsboat", "tab") end
function M.terminal_newterm_tab() toggle_term("newtab", vim.o.shell, "tab") end
function M.terminal_qwen_toggle() toggle_term("qwen", "qwen", "vertical") end
function M.terminal_gemini_toggle() toggle_term("gemini", "gemini", "vertical") end
function M.terminal_cursor_agent_toggle() toggle_term("cursor", "cursor-agent", "vertical") end
function M.terminal_kimi_claude_code_toggle()
	local cmd = "ANTHROPIC_BASE_URL=https://api.moonshot.cn/anthropic/ ANTHROPIC_API_KEY=$(cat ~/work/password/kimi-cc) claude"
	toggle_term("kimi", cmd, "tab")
end

-- Tab 终端（Claude/Codex）
function M.tab_terminal_claude(api_num)
	local cmd = api_num and build_claude_cmd(api_num) or "claude"
	toggle_term("claude_" .. (api_num or "default"), cmd, "tab")
end

function M.tab_terminal_claude_new(api_num)
	local cmd = api_num and build_claude_cmd(api_num) or "claude"
	local name = "claude_new_" .. os.time()
	create_tab_term(name, cmd)
end

function M.tab_terminal_codex()
	toggle_term("codex", "codex", "tab")
end

-- 灵活的 Claude 启动器（支持多种显示方式）
function M.claude_launcher()
	-- 第一步：选择 API
	vim.ui.select(
		{ "API 1", "API 2", "Default" },
		{ prompt = "选择 Claude API:" },
		function(api_choice)
			if not api_choice then return end
			local api_num = api_choice == "API 1" and 1 or (api_choice == "API 2" and 2 or nil)

			-- 第二步：选择显示方式
			vim.ui.select(
				{ "新 Tab", "浮动窗口 (大)", "半屏 (右侧)", "水平分割", "垂直分割" },
				{ prompt = "选择显示方式:" },
				function(display_choice)
					if not display_choice then return end

					local cmd = api_num and build_claude_cmd(api_num) or "claude"

					if display_choice == "新 Tab" then
						local name = "claude_new_" .. os.time()
						create_tab_term(name, cmd)
					elseif display_choice == "浮动窗口 (大)" then
						local name = "claude_float_temp_" .. os.time()
						create_float_term(name, cmd, {
							width = math.floor(vim.o.columns * 0.8),
							height = math.floor(vim.o.lines * 0.8),
							title = " Claude [" .. (api_choice or "Default") .. "] "
						})
					elseif display_choice == "半屏 (右侧)" then
						local tabpage = vim.api.nvim_get_current_tabpage()
						local key = string.format("tab_%d_claude_half", tabpage)
						local width = math.floor(vim.o.columns * 0.5)
						local height = vim.o.lines - 4
						local tab_nr = vim.api.nvim_tabpage_get_number(tabpage)

						local cfg = {
							width = width,
							height = height,
							row = 1,
							col = vim.o.columns - width - 1,
							title = " Claude [T" .. tab_nr .. "] ",
						}

						local state = float_terminals[key]
						if not state or not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
							create_float_terminal(key, function() return cmd end, cfg)
						else
							reopen_float_window(key, cfg)
						end
					elseif display_choice == "水平分割" then
						local name = "claude_hsplit_" .. os.time()
						create_horizontal_term(name, cmd, { height = math.floor(vim.o.lines * 0.4) })
					elseif display_choice == "垂直分割" then
						local name = "claude_vsplit_" .. os.time()
						create_vertical_term(name, cmd, { width = math.floor(vim.o.columns * 0.4) })
					end
				end
			)
		end
	)
end

-- 启动 lazygit 浮动终端（原生实现）
local function open_lazygit_float(dir)
	local width = math.floor(vim.o.columns * 0.9)
	local height = math.floor(vim.o.lines * 0.9)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = " Lazygit ",
		title_pos = "center",
	})

	local cmd = "lazygit"
	if dir then
		cmd = "cd " .. vim.fn.shellescape(dir) .. " && lazygit"
	end

	vim.fn.termopen(cmd, {
		env = get_term_env(),
		on_exit = function()
			pcall(vim.api.nvim_win_close, win, true)
		end,
	})
	vim.cmd("startinsert")
end
M.open_lazygit_float = open_lazygit_float

-- ============================================================================
-- 浮动终端（原生 API 实现，智能避让布局）
-- 支持 Claude 终端和普通终端
-- ============================================================================
local float_terminals = {}
local float_api_select_enabled = false  -- API 选择开关

-- 获取当前目录下所有 git 仓库的分支信息
local function get_multi_repo_branches()
	local cwd = vim.fn.getcwd()
	local repos = {}

	-- 检查当前目录本身是否是 git repo
	local current_branch = vim.fn.system("git -C " .. vim.fn.shellescape(cwd) .. " branch --show-current 2>/dev/null"):gsub("%s+", "")
	if current_branch ~= "" then
		local repo_name = vim.fn.fnamemodify(cwd, ":t")
		table.insert(repos, { name = repo_name, branch = current_branch, path = cwd })
	end

	-- 查找子目录中的 git repos
	local subdirs = vim.fn.glob(cwd .. "/*/.git", false, true)
	for _, git_dir in ipairs(subdirs) do
		local repo_path = vim.fn.fnamemodify(git_dir, ":h")
		local repo_name = vim.fn.fnamemodify(repo_path, ":t")
		local branch = vim.fn.system("git -C " .. vim.fn.shellescape(repo_path) .. " branch --show-current 2>/dev/null"):gsub("%s+", "")
		if branch ~= "" then
			table.insert(repos, { name = repo_name, branch = branch, path = repo_path })
		end
	end

	return repos
end

function M.float_toggle_api_select()
	float_api_select_enabled = not float_api_select_enabled
	vim.notify("Float API Select: " .. (float_api_select_enabled and "ON" or "OFF"), vim.log.levels.INFO)
end

local function get_open_positions()
	local positions = {}
	for _, state in pairs(float_terminals) do
		if state.win and vim.api.nvim_win_is_valid(state.win) then
			local cfg = vim.api.nvim_win_get_config(state.win)
			-- 只收集浮动窗口的位置（relative 不为空且 row/col 存在）
			if cfg.relative and cfg.relative ~= "" and cfg.row and cfg.col then
				table.insert(positions, { row = cfg.row, col = cfg.col })
			end
		end
	end
	return positions
end

local function find_free_position(preferred_row, preferred_col, width, height)
	local open_pos = get_open_positions()
	local offset_step = 3
	local row, col = preferred_row, preferred_col
	local screen_w = vim.o.columns
	local screen_h = vim.o.lines

	local function is_overlapping(r, c)
		for _, pos in ipairs(open_pos) do
			if math.abs(r - pos.row) < height and math.abs(c - pos.col) < width then
				return true
			end
		end
		return false
	end

	local attempts = 0
	while is_overlapping(row, col) and attempts < 10 do
		col = col - offset_step
		row = row + offset_step
		if col < 1 then col = screen_w - width - 1 end
		if row > screen_h - height - 4 then row = 1 end
		attempts = attempts + 1
	end

	return row, col
end

local function get_float_config(id, type, tabpage)
	local width = 60
	local height = 16
	local screen_w = vim.o.columns
	local tab_nr = vim.api.nvim_tabpage_get_number(tabpage or vim.api.nvim_get_current_tabpage())

	local configs = {
		claude = {
			[1] = { title = " Claude 1 " },
			[2] = { title = " Claude 2 " },
			[3] = { title = " Claude 3 " },
			[4] = { title = " Claude 4 " },
			[5] = { title = " Claude [nvim] ", cwd = "~/.config/nvim" },
			[6] = { title = " Claude [kitty] ", cwd = "~/.config/kitty" },
		},
		term = {
			[1] = { title = " Terminal 1 " },
			[2] = { title = " Terminal 2 " },
			[3] = { title = " Terminal 3 " },
			[4] = { title = " Terminal 4 " },
		},
	}

	local cfg = (configs[type] or {})[id] or { title = " Float " .. id }
	local row, col = find_free_position(1, screen_w - width - 1, width, height)

	-- 在标题中显示 tab 编号
	local title = cfg.title:gsub(" $", "") .. " [T" .. tab_nr .. "] "

	return {
		width = width,
		height = height,
		row = row,
		col = col,
		title = title,
		cwd = cfg.cwd,
	}
end

local function create_float_terminal(key, cmd_fn, cfg)
	local buf = vim.api.nvim_create_buf(false, true)
	float_terminals[key] = { buf = buf, win = nil }

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = cfg.width,
		height = cfg.height,
		row = cfg.row,
		col = cfg.col,
		style = "minimal",
		border = "rounded",
		title = cfg.title,
		title_pos = "center",
	})
	float_terminals[key].win = win

	local cmd = cmd_fn()
	if cfg.cwd then
		cmd = "cd " .. vim.fn.expand(cfg.cwd) .. " && " .. cmd
	end
	-- 确保 PATH 包含常用路径 (解决 node 找不到问题)
	local env = vim.fn.environ()
	env.PATH = vim.fn.expand("$HOME/.local/bin") .. ":" .. vim.fn.expand("$HOME/.nvm/versions/node/v22.12.0/bin") .. ":" .. (env.PATH or "")
	vim.fn.termopen(cmd, {
		env = env,
		on_exit = function()
			if float_terminals[key] then
				float_terminals[key].buf = nil
			end
		end,
	})
	vim.cmd("startinsert")

	-- terminal normal mode 下 q 关闭 (先 <C-\><C-n> 退出输入模式，再按 q)
	vim.keymap.set("n", "q", function()
		if float_terminals[key] and float_terminals[key].win and vim.api.nvim_win_is_valid(float_terminals[key].win) then
			vim.api.nvim_win_close(float_terminals[key].win, true)
			float_terminals[key].win = nil
		end
	end, { buffer = buf, noremap = true, silent = true })
end

local function reopen_float_window(key, cfg)
	local state = float_terminals[key]
	local win = vim.api.nvim_open_win(state.buf, true, {
		relative = "editor",
		width = cfg.width,
		height = cfg.height,
		row = cfg.row,
		col = cfg.col,
		style = "minimal",
		border = "rounded",
		title = cfg.title,
		title_pos = "center",
	})
	float_terminals[key].win = win
	vim.cmd("startinsert")
end

local function select_api_and_run(callback)
	vim.ui.select({ "API 1", "API 2", "Default" }, { prompt = "Select Claude API:" }, function(choice)
		if not choice then return end
		local api_num = choice == "API 1" and 1 or (choice == "API 2" and 2 or nil)
		callback(api_num)
	end)
end

local function float_toggle(id, type)
	local tabpage = vim.api.nvim_get_current_tabpage()
	local key = string.format("tab_%d_%s_%s", tabpage, type, id)
	local state = float_terminals[key]

	-- 如果窗口已存在，关闭它
	if state and state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
		float_terminals[key].win = nil
		return
	end

	local cfg = get_float_config(id, type, tabpage)

	-- buffer 不存在，需要创建
	if not state or not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
		if type == "claude" and float_api_select_enabled then
			select_api_and_run(function(api_num)
				create_float_terminal(key, function()
					return api_num and build_claude_cmd(api_num) or "claude"
				end, cfg)
			end)
		elseif type == "claude" then
			create_float_terminal(key, function() return "claude" end, cfg)
		else
			create_float_terminal(key, function() return vim.o.shell end, cfg)
		end
	else
		reopen_float_window(key, cfg)
	end
end

function M.claude_float_1_toggle() float_toggle(1, "claude") end
function M.claude_float_2_toggle() float_toggle(2, "claude") end
function M.claude_float_3_toggle() float_toggle(3, "claude") end
function M.claude_float_4_toggle() float_toggle(4, "claude") end
function M.claude_float_nvim_toggle() float_toggle(5, "claude") end
function M.claude_float_kitty_toggle() float_toggle(6, "claude") end

function M.claude_half_screen_toggle()
	local tabpage = vim.api.nvim_get_current_tabpage()
	local key = string.format("tab_%d_claude_half", tabpage)
	local state = float_terminals[key]

	if state and state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
		float_terminals[key].win = nil
		return
	end

	local width = math.floor(vim.o.columns * 0.5)
	local height = vim.o.lines - 4
	local tab_nr = vim.api.nvim_tabpage_get_number(tabpage)

	local cfg = {
		width = width,
		height = height,
		row = 1,
		col = vim.o.columns - width - 1,
		title = " Claude [T" .. tab_nr .. "] ",
	}

	if not state or not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
		create_float_terminal(key, function() return "claude" end, cfg)
	else
		reopen_float_window(key, cfg)
	end
end

function M.term_float_1_toggle() float_toggle(1, "term") end
function M.term_float_2_toggle() float_toggle(2, "term") end
function M.term_float_3_toggle() float_toggle(3, "term") end
function M.term_float_4_toggle() float_toggle(4, "term") end

function M.claude_float_toggle_all()
	local tabpage = vim.api.nvim_get_current_tabpage()
	local prefix = string.format("tab_%d_claude_", tabpage)

	local any_open = false
	for key, state in pairs(float_terminals) do
		if key:match("^" .. prefix) and state.win and vim.api.nvim_win_is_valid(state.win) then
			any_open = true
			break
		end
	end

	if any_open then
		for key, state in pairs(float_terminals) do
			if key:match("^" .. prefix) and state.win and vim.api.nvim_win_is_valid(state.win) then
				vim.api.nvim_win_close(state.win, true)
				float_terminals[key].win = nil
			end
		end
	else
		for key, state in pairs(float_terminals) do
			if key:match("^" .. prefix) and state.buf and vim.api.nvim_buf_is_valid(state.buf) then
				local id = key:match(prefix .. "(%d+)")
				if id then float_toggle(tonumber(id), "claude") end
			end
		end
	end
end

function M.term_float_toggle_all()
	local tabpage = vim.api.nvim_get_current_tabpage()
	local prefix = string.format("tab_%d_term_", tabpage)

	local any_open = false
	for key, state in pairs(float_terminals) do
		if key:match("^" .. prefix) and state.win and vim.api.nvim_win_is_valid(state.win) then
			any_open = true
			break
		end
	end

	if any_open then
		for key, state in pairs(float_terminals) do
			if key:match("^" .. prefix) and state.win and vim.api.nvim_win_is_valid(state.win) then
				vim.api.nvim_win_close(state.win, true)
				float_terminals[key].win = nil
			end
		end
	else
		for key, state in pairs(float_terminals) do
			if key:match("^" .. prefix) and state.buf and vim.api.nvim_buf_is_valid(state.buf) then
				local id = key:match(prefix .. "(%d+)")
				if id then float_toggle(tonumber(id), "term") end
			end
		end
	end
end

function M.float_hide_all()
	local tabpage = vim.api.nvim_get_current_tabpage()
	local prefix = string.format("tab_%d_", tabpage)
	for key, state in pairs(float_terminals) do
		if key:match("^" .. prefix) and state.win and vim.api.nvim_win_is_valid(state.win) then
			vim.api.nvim_win_close(state.win, true)
			float_terminals[key].win = nil
		end
	end
end

-- 显示所有 git repo 分支状态（浮动窗口）
function M.show_multi_repo_branches()
	local repos = get_multi_repo_branches()
	if #repos == 0 then
		vim.notify("当前目录下没有 git 仓库", vim.log.levels.WARN)
		return
	end

	local lines = { "  Git Repositories Branches", "  " .. string.rep("─", 40) }
	for _, repo in ipairs(repos) do
		-- 获取更多状态信息
		local status_cmd = "git -C " .. vim.fn.shellescape(repo.path) .. " status --porcelain 2>/dev/null | wc -l"
		local changes = vim.fn.system(status_cmd):gsub("%s+", "")
		local change_indicator = tonumber(changes) > 0 and " ✱" or ""

		local display_path = repo.path:gsub(vim.fn.expand("~"), "~")
		table.insert(lines, string.format("  %s: %s%s", repo.name, repo.branch, change_indicator))
		table.insert(lines, string.format("    %s", display_path))
	end
	table.insert(lines, "")
	table.insert(lines, "  [q] 关闭  [g] 刷新  [enter] 打开 lazygit")

	-- 创建浮动窗口
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"

	local width = 50
	local height = #lines
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = " Multi-Repo Branches ",
		title_pos = "center",
	})

	-- 高亮设置
	vim.api.nvim_buf_add_highlight(buf, -1, "Title", 0, 0, -1)
	for i = 2, #lines - 2 do
		if i % 2 == 1 then
			vim.api.nvim_buf_add_highlight(buf, -1, "Function", i, 0, -1)
		else
			vim.api.nvim_buf_add_highlight(buf, -1, "Comment", i, 0, -1)
		end
	end
	vim.api.nvim_buf_add_highlight(buf, -1, "Comment", #lines - 1, 0, -1)

	-- 快捷键
	local close_win = function()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	vim.keymap.set("n", "q", close_win, { buffer = buf, nowait = true })
	vim.keymap.set("n", "<Esc>", close_win, { buffer = buf, nowait = true })
	vim.keymap.set("n", "g", function()
		close_win()
		M.show_multi_repo_branches()
	end, { buffer = buf, nowait = true })

	-- Enter 打开 lazygit（使用当前光标所在的 repo）
	vim.keymap.set("n", "<CR>", function()
		local cursor_line = vim.api.nvim_win_get_cursor(win)[1]
		local repo_idx = math.floor((cursor_line - 2) / 2) + 1
		if repos[repo_idx] then
			close_win()
			open_lazygit_float(repos[repo_idx].path)
		end
	end, { buffer = buf, nowait = true })
end

function M.terminal_scroll_up()
	vim.cmd([[stopinsert]])
	vim.schedule(function()
		local half_page = math.floor(vim.api.nvim_win_get_height(0) / 2)
		vim.cmd("normal! " .. half_page .. "k")
	end)
end

-- ============================================================================
-- Editor: Tab
-- ============================================================================
function M.tab_rename()
	vim.ui.input({ prompt = "Tab name: " }, function(name)
		if name and name ~= "" then
			vim.t.tab_name = name
			vim.cmd.redrawtabline()
		end
	end)
end

function M.tab_clear_name()
	vim.t.tab_name = nil
	vim.cmd.redrawtabline()
end

-- ============================================================================
-- Tools: Telescope
-- ============================================================================
function M.telescope_copy_file_content()
	require("telescope.builtin").find_files({
		prompt_title = "Copy File Content",
		attach_mappings = function(prompt_bufnr, map)
			local actions = require("telescope.actions")
			local action_state = require("telescope.actions.state")
			map("i", "<CR>", function()
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)
				if selection then
					local file_path = selection.path or selection.value
					local file_content = vim.fn.readfile(file_path)
					local row = vim.api.nvim_win_get_cursor(0)[1]
					vim.api.nvim_buf_set_lines(0, row, row, false, file_content)
					print("File content copied: " .. file_path)
				end
			end)
			return true
		end,
	})
end

-- ============================================================================
-- Git
-- ============================================================================
local last_selected_repo = nil

function M.git_lazygit_last_repo()
	if not last_selected_repo then
		vim.notify("还没有选择过仓库", vim.log.levels.WARN)
		return
	end
	open_lazygit_float(vim.fn.fnamemodify(last_selected_repo, ":p"))
end

function M.git_lazygit_multi_repo()
	local git_dirs = vim.fn.systemlist("find . -maxdepth 3 -type d -name '.git' 2>/dev/null | sed 's|/.git||' | sort")
	if #git_dirs == 0 then
		vim.notify("未找到任何 git 仓库", vim.log.levels.WARN)
		return
	end
	require("telescope.pickers").new({}, {
		prompt_title = "选择 Git 仓库",
		finder = require("telescope.finders").new_table({
			results = git_dirs,
			entry_maker = function(entry)
				local display = entry:gsub("^%./", "")
				if entry == last_selected_repo then display = "★ " .. display end
				return { value = entry, display = display, ordinal = display }
			end,
		}),
		sorter = require("telescope.config").values.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, map)
			require("telescope.actions").select_default:replace(function()
				require("telescope.actions").close(prompt_bufnr)
				local selection = require("telescope.actions.state").get_selected_entry()
				if selection then
					last_selected_repo = selection.value
					open_lazygit_float(vim.fn.fnamemodify(selection.value, ":p"))
				end
			end)
			return true
		end,
	}):find()
end

-- 通用多 repo 选择器，选择后在该 repo 目录下执行回调
local function select_repo_and_run(callback, prompt_title)
	local git_dirs = vim.fn.systemlist("find . -maxdepth 3 -type d -name '.git' 2>/dev/null | sed 's|/.git||' | sort")
	if #git_dirs == 0 then
		vim.notify("未找到任何 git 仓库", vim.log.levels.WARN)
		return
	end
	-- 只有一个 repo 时直接执行
	if #git_dirs == 1 then
		local repo_path = vim.fn.fnamemodify(git_dirs[1], ":p")
		callback(repo_path)
		return
	end
	require("telescope.pickers").new({}, {
		prompt_title = prompt_title or "选择 Git 仓库",
		finder = require("telescope.finders").new_table({
			results = git_dirs,
			entry_maker = function(entry)
				local display = entry:gsub("^%./", "")
				if entry == last_selected_repo then display = "★ " .. display end
				return { value = entry, display = display, ordinal = display }
			end,
		}),
		sorter = require("telescope.config").values.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, map)
			require("telescope.actions").select_default:replace(function()
				require("telescope.actions").close(prompt_bufnr)
				local selection = require("telescope.actions.state").get_selected_entry()
				if selection then
					last_selected_repo = selection.value
					local repo_path = vim.fn.fnamemodify(selection.value, ":p")
					callback(repo_path)
				end
			end)
			return true
		end,
	}):find()
end

-- GitLab: 选择 repo 后执行 gitlab 操作
function M.gitlab_with_repo(action)
	select_repo_and_run(function(repo_path)
		-- 临时切换目录执行 gitlab 操作
		local old_cwd = vim.fn.getcwd()
		vim.cmd("cd " .. vim.fn.fnameescape(repo_path))
		-- 重新初始化 gitlab.nvim 的项目设置
		vim.defer_fn(function()
			local ok, gitlab = pcall(require, "gitlab")
			if ok then
				if action == "create_mr" then
					gitlab.create_mr()
				elseif action == "review" then
					gitlab.review()
				elseif action == "summary" then
					gitlab.summary()
				elseif action == "choose_merge_request" then
					gitlab.choose_merge_request()
				elseif action == "pipeline" then
					gitlab.pipeline()
				elseif action == "open_in_browser" then
					gitlab.open_in_browser()
				end
			end
		end, 100)
	end, "选择仓库 - GitLab " .. action)
end

-- GitLab: 在浏览器打开创建 MR 页面
function M.gitlab_create_mr_web()
	local branch = vim.fn.systemlist("git branch --show-current")[1]
	if not branch or branch == "" then
		vim.notify("未找到当前分支", vim.log.levels.ERROR)
		return
	end
	vim.fn.jobstart("glab mr create --web", { detach = true })
	vim.notify("正在浏览器打开创建 MR 页面...", vim.log.levels.INFO)
end

function M.git_compare_head()
	local file = vim.api.nvim_buf_get_name(0)
	if file == "" then
		vim.notify("当前 buffer 没有关联文件", vim.log.levels.WARN)
		return
	end
	local git_root = vim.fn.systemlist("git -C " .. vim.fn.fnameescape(vim.fn.expand("%:p:h")) .. " rev-parse --show-toplevel")[1]
	if not git_root or git_root == "" then
		vim.notify("未找到 git 仓库根目录", vim.log.levels.ERROR)
		return
	end
	local relpath = file:sub(#git_root + 2)
	vim.cmd("tabnew")
	vim.cmd("edit " .. file)
	vim.cmd("vsplit")
	vim.cmd("wincmd j")
	vim.cmd("Gedit HEAD:" .. relpath)
	vim.cmd("wincmd k")
end

-- ============================================================================
-- Debug (DAP)
-- ============================================================================
function M.dap_conditional_breakpoint()
	require('persistent-breakpoints.api').set_conditional_breakpoint()
end

function M.dap_eval_input()
	require('dap').eval(vim.fn.input('[Expression] > '))
end

function M.dap_toggle_ui()
	local dapui = require("dapui")
	local is_open = false
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
		if name:match("DAP") then is_open = true break end
	end
	if is_open then
		dapui.close()
		vim.o.mouse = ""
	else
		dapui.open()
		vim.o.mouse = "a"
	end
end

function M.dap_restart()
	require("dap").terminate()
	vim.defer_fn(function() require("dap").run_last() end, 100)
end

function M.dap_enable_all_breakpoints()
	local dap = require("dap")
	for _, bp in pairs(dap.breakpoints) do
		for _, breakpoint in pairs(bp) do breakpoint.enabled = true end
	end
	dap.refresh_breakpoints()
end

function M.dap_disable_all_breakpoints()
	local dap = require("dap")
	for _, bp in pairs(dap.breakpoints) do
		for _, breakpoint in pairs(bp) do breakpoint.enabled = false end
	end
	dap.refresh_breakpoints()
end

function M.dap_clear_all_breakpoints()
	require('persistent-breakpoints.api').clear_all_breakpoints()
end

function M.dap_toggle_breakpoint()
	require('persistent-breakpoints.api').toggle_breakpoint()
end

-- ============================================================================
-- Workspace
-- ============================================================================
local function get_workspaces_config()
	return require("plugins.config.workspaces")
end

function M.workspace_add_project() get_workspaces_config().add_project_to_workspace() end
function M.workspace_add_project_path()
	vim.ui.input({ prompt = "Project path: ", completion = "dir" }, function(path)
		if path then get_workspaces_config().add_project_to_workspace(vim.fn.expand(path)) end
	end)
end
function M.workspace_remove_project() get_workspaces_config().remove_project_from_workspace() end
function M.workspace_list_projects() get_workspaces_config().list_workspace_projects() end
function M.workspace_switch_root() get_workspaces_config().switch_project_root() end
function M.workspace_search_all() get_workspaces_config().search_all_projects() end
function M.workspace_search_all_hidden() get_workspaces_config().search_all_projects_with_hidden() end
function M.workspace_grep_all() get_workspaces_config().grep_all_projects() end
function M.workspace_grep_all_hidden() get_workspaces_config().grep_all_projects_with_hidden() end

-- ============================================================================
-- Sessions
-- ============================================================================
local function get_possession_config()
	return require("plugins.config.possession")
end

function M.session_save_workspace() get_possession_config().save_workspace_session() end
function M.session_load_workspace() get_possession_config().load_workspace_session() end
function M.session_delete_workspace() get_possession_config().delete_workspace_session() end
function M.session_list_workspace() get_possession_config().list_workspace_sessions() end
function M.session_telescope()
	if pcall(require, "telescope") then
		vim.cmd("Telescope possession")
	else
		vim.cmd("PossessionList")
	end
end

-- ============================================================================
-- Neotest
-- ============================================================================
function M.neotest_all()
	local common = require("core.common")
	local project_root = common.find_project_root_by_marker("pyproject.toml") or vim.loop.getcwd()
	require("neotest").run.run(project_root)
end

-- ============================================================================
-- Project
-- ============================================================================
function M.project_reset_root()
	require("project_nvim.project").set_pwd()
end

function M.project_manual_set_root()
	vim.ui.input({ prompt = "Enter project root path: " }, function(input)
		if input then
			vim.cmd("cd " .. input)
			require("project_nvim.project").set_pwd()
		end
	end)
end

-- ============================================================================
-- Overseer
-- ============================================================================
function M.overseer_go_build()
	require("overseer").run_task({ name = "Go Build" })
end

function M.overseer_run_script()
	require("overseer").run_task({ name = "run script" })
end

function M.overseer_run_script_args()
	require("overseer").run_task({ name = "run script with args" })
end

-- ============================================================================
-- Ufo Fold
-- ============================================================================
function M.ufo_fold_except_current()
	require("ufo").closeAllFolds()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	if vim.fn.foldclosed(row) ~= -1 then
		vim.cmd(row .. "foldopen")
	end
end

function M.ufo_focus_next_fold()
	vim.cmd("normal! zc")
	require("ufo").goNextClosedFold()
	vim.cmd("normal! zO")
	vim.cmd("normal! zz")
end

-- ============================================================================
-- Android
-- ============================================================================
local function get_android_config()
	local ok, android = pcall(require, "plugins.config.android")
	return ok and android or nil
end

function M.android_adb_picker()
	local android = get_android_config()
	if android then android.adb_picker() end
end

function M.android_gradle_picker()
	local android = get_android_config()
	if android then android.gradle_picker() end
end

function M.android_show_error_log()
	local android = get_android_config()
	if android then android.show_error_log() end
end

-- ============================================================================
-- Git: 多 Repo 支持
-- ============================================================================

-- 多 repo 变更查看器
local multi_repo_state = { buf = nil, win = nil, items = {} }

local function close_multi_repo_viewer()
	if multi_repo_state.win and vim.api.nvim_win_is_valid(multi_repo_state.win) then
		vim.api.nvim_win_close(multi_repo_state.win, true)
	end
	multi_repo_state.win = nil
end

-- 渲染多 repo 变更查看器
local function render_multi_repo_viewer(repos_with_changes, total_repos)
	local lines = {}
	local items = {}
	local total_changes = 0

	for _, repo_data in ipairs(repos_with_changes) do
		local repo_name = vim.fn.fnamemodify(repo_data.path, ":t")
		if #repo_data.changes > 0 then
			table.insert(lines, "")
			table.insert(items, { type = "header" })
			table.insert(lines, string.format("## %s (%d)", repo_name, #repo_data.changes))
			table.insert(items, { type = "repo", path = repo_data.path })

			for _, change in ipairs(repo_data.changes) do
				local icon = change.status == "M" and "~" or (change.status == "A" and "+" or (change.status == "D" and "-" or "?"))
				table.insert(lines, string.format("   %s %s", icon, change.file))
				table.insert(items, { type = "file", status = change.status, file = change.file, repo = repo_data.path })
				total_changes = total_changes + 1
			end
		end
	end

	if total_changes == 0 then
		vim.notify("All repos are clean!", vim.log.levels.INFO)
		return
	end

	table.insert(lines, "")
	table.insert(items, { type = "footer" })
	table.insert(lines, "─────────────────────────────────────────────────────────")
	table.insert(items, { type = "footer" })
	table.insert(lines, string.format(" Total: %d repos, %d changes", total_repos, total_changes))
	table.insert(items, { type = "footer" })
	table.insert(lines, "")
	table.insert(items, { type = "footer" })
	table.insert(lines, " [Enter] open  [d] diff  [D] repo diff  [g] lazygit  [q] close")
	table.insert(items, { type = "footer" })

	multi_repo_state.items = items

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

	local width = math.min(70, vim.o.columns - 10)
	local height = math.min(#lines + 2, vim.o.lines - 10)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		title = " Multi-Repo Changes ",
		title_pos = "center",
	})

	multi_repo_state.buf = buf
	multi_repo_state.win = win

	vim.api.nvim_win_set_option(win, "cursorline", true)
	vim.api.nvim_win_set_option(win, "wrap", false)

	local opts = { buffer = buf, noremap = true, silent = true }

	vim.keymap.set("n", "q", close_multi_repo_viewer, opts)
	vim.keymap.set("n", "<Esc>", close_multi_repo_viewer, opts)

	vim.keymap.set("n", "<CR>", function()
		local line = vim.api.nvim_win_get_cursor(win)[1]
		local item = items[line]
		if item and item.type == "file" then
			close_multi_repo_viewer()
			local full_path = item.repo .. "/" .. item.file
			vim.cmd("edit " .. full_path)
		end
	end, opts)

	vim.keymap.set("n", "d", function()
		local line = vim.api.nvim_win_get_cursor(win)[1]
		local item = items[line]
		if item and item.type == "file" then
			vim.cmd("DiffviewOpen -C" .. item.repo .. " -- " .. item.file)
		end
	end, opts)

	vim.keymap.set("n", "D", function()
		local line = vim.api.nvim_win_get_cursor(win)[1]
		local item = items[line]
		local repo_path = nil
		if item and item.type == "file" then
			repo_path = item.repo
		elseif item and item.type == "repo" then
			repo_path = item.path
		end
		if repo_path then
			vim.cmd("DiffviewOpen -C" .. repo_path)
		end
	end, opts)

	-- g 打开 lazygit
	vim.keymap.set("n", "g", function()
		local line = vim.api.nvim_win_get_cursor(win)[1]
		local item = items[line]
		local repo_path = nil
		if item and item.type == "file" then
			repo_path = item.repo
		elseif item and item.type == "repo" then
			repo_path = item.path
		end
		if repo_path then
			open_lazygit_float(repo_path)
		end
	end, opts)

	-- 移动到第一个文件行
	for i, item in ipairs(items) do
		if item.type == "file" then
			vim.api.nvim_win_set_cursor(win, { i, 0 })
			break
		end
	end
end

-- 异步获取多 repo 变更
function M.diffview_multi_repo()
	local cwd = vim.fn.getcwd()

	-- 显示加载提示
	vim.notify("Scanning repos...", vim.log.levels.INFO)

	-- 异步执行 find 命令
	vim.system(
		{ "find", cwd, "-maxdepth", "2", "-name", ".git", "-type", "d" },
		{ text = true },
		function(find_result)
			if find_result.code ~= 0 or not find_result.stdout or find_result.stdout == "" then
				vim.schedule(function()
					vim.notify("No git repos found in " .. cwd, vim.log.levels.WARN)
				end)
				return
			end

			-- 解析 repo 路径
			local repos = {}
			for line in find_result.stdout:gmatch("[^\n]+") do
				local repo_path = line:gsub("/.git$", "")
				table.insert(repos, repo_path)
			end

			if #repos == 0 then
				vim.schedule(function()
					vim.notify("No git repos found in " .. cwd, vim.log.levels.WARN)
				end)
				return
			end

			-- 异步获取每个 repo 的变更
			local repos_with_changes = {}
			local pending = #repos

			for _, repo_path in ipairs(repos) do
				vim.system(
					{ "git", "-C", repo_path, "status", "--porcelain" },
					{ text = true },
					function(status_result)
						local changes = {}
						if status_result.code == 0 and status_result.stdout then
							for line in status_result.stdout:gmatch("[^\n]+") do
								if line ~= "" then
									local status = line:sub(1, 2):gsub("%s", "")
									local file = line:sub(4)
									table.insert(changes, { status = status, file = file })
								end
							end
						end
						table.insert(repos_with_changes, { path = repo_path, changes = changes })

						pending = pending - 1
						if pending == 0 then
							-- 所有 repo 处理完成，渲染结果
							vim.schedule(function()
								-- 按路径排序
								table.sort(repos_with_changes, function(a, b) return a.path < b.path end)
								render_multi_repo_viewer(repos_with_changes, #repos)
							end)
						end
					end
				)
			end
		end
	)
end

-- 显示所有 repo 的变更概览（简化版，异步）
function M.diffview_multi_repo_status()
	local cwd = vim.fn.getcwd()

	vim.system(
		{ "find", cwd, "-maxdepth", "2", "-name", ".git", "-type", "d" },
		{ text = true },
		function(find_result)
			if find_result.code ~= 0 or not find_result.stdout or find_result.stdout == "" then
				vim.schedule(function()
					vim.notify("No git repos found in " .. cwd, vim.log.levels.WARN)
				end)
				return
			end

			local repos = {}
			for line in find_result.stdout:gmatch("[^\n]+") do
				local repo_path = line:gsub("/.git$", "")
				table.insert(repos, repo_path)
			end

			if #repos == 0 then
				vim.schedule(function()
					vim.notify("No git repos found in " .. cwd, vim.log.levels.WARN)
				end)
				return
			end

			local results = {}
			local pending = #repos

			for _, repo_path in ipairs(repos) do
				vim.system(
					{ "git", "-C", repo_path, "status", "--porcelain" },
					{ text = true },
					function(status_result)
						local count = 0
						if status_result.code == 0 and status_result.stdout then
							for _ in status_result.stdout:gmatch("[^\n]+") do
								count = count + 1
							end
						end
						table.insert(results, { path = repo_path, count = count })

						pending = pending - 1
						if pending == 0 then
							vim.schedule(function()
								table.sort(results, function(a, b) return a.path < b.path end)

								local lines = { "# Git Repos Status", "" }
								local total_changes = 0

								for _, r in ipairs(results) do
									local name = vim.fn.fnamemodify(r.path, ":t")
									if r.count > 0 then
										table.insert(lines, string.format("  %s: %d changes", name, r.count))
										total_changes = total_changes + r.count
									else
										table.insert(lines, string.format("  %s: clean", name))
									end
								end

								table.insert(lines, "")
								table.insert(lines, string.format("Total: %d repos, %d changes", #repos, total_changes))

								local buf = vim.api.nvim_create_buf(false, true)
								vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
								vim.api.nvim_buf_set_option(buf, "modifiable", false)

								local width = 50
								local height = #lines + 2
								local win = vim.api.nvim_open_win(buf, true, {
									relative = "editor",
									width = width,
									height = height,
									row = math.floor((vim.o.lines - height) / 2),
									col = math.floor((vim.o.columns - width) / 2),
									style = "minimal",
									border = "rounded",
									title = " Multi-Repo Status ",
									title_pos = "center",
								})

								vim.keymap.set("n", "q", function() vim.api.nvim_win_close(win, true) end, { buffer = buf })
								vim.keymap.set("n", "<Esc>", function() vim.api.nvim_win_close(win, true) end, { buffer = buf })
							end)
						end
					end
				)
			end
		end
	)
end

-- ============================================================================
-- NvimTree Float
-- ============================================================================
function M.nvim_tree_float()
	local view = require("nvim-tree.view")
	local api = require("nvim-tree.api")

	-- 先关闭已有的 tree
	api.tree.close()

	-- 计算居中位置
	local width = math.floor(vim.o.columns * 0.6)
	local height = math.floor(vim.o.lines * 0.7)
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	-- 临时修改 view 配置为浮动
	view.View.float.enable = true
	view.View.float.open_win_config = {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		border = "rounded",
	}

	-- 打开 tree
	api.tree.open()

	-- 恢复为非浮动模式（下次正常打开时用侧边栏）
	vim.schedule(function()
		view.View.float.enable = false
	end)

	-- 设置 enter 行为：目录展开，文件才关闭浮动窗口
	local bufnr = vim.api.nvim_get_current_buf()
	vim.keymap.set("n", "<CR>", function()
		local node = api.tree.get_node_under_cursor()
		if node and node.type == "directory" then
			api.node.open.edit() -- 展开目录，不关闭
		else
			api.node.open.edit()
			api.tree.close() -- 打开文件后关闭
		end
	end, { buffer = bufnr, nowait = true })
end

-- ============================================================================
-- Mail: aerc
-- ============================================================================
function M.mail_aerc()
	local tabpage = vim.api.nvim_get_current_tabpage()
	local key = string.format("tab_%d_mail_aerc", tabpage)
	local state = float_terminals[key]

	-- 如果窗口已存在，关闭它
	if state and state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
		float_terminals[key].win = nil
		return
	end

	local cfg = {
		width = math.floor(vim.o.columns * 0.8),
		height = math.floor(vim.o.lines * 0.8),
		row = math.floor(vim.o.lines * 0.1),
		col = math.floor(vim.o.columns * 0.1),
		title = " aerc - Mail ",
	}

	if not state or not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
		create_float_terminal(key, function() return "aerc" end, cfg)
	else
		reopen_float_window(key, cfg)
	end
end

return M
