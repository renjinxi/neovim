local M = {}

function M.setup(opts)
	local api = {}
	local terminal = assert(opts.terminal, "float_runtime requires terminal")
	local float_terminals = {}
	local float_api_select_enabled = false
	local ai_float_profiles = {}
	local build_ai_command
	local build_ai_label

	function api.set_ai_state(state)
		ai_float_profiles = state.ai_float_profiles or ai_float_profiles
		build_ai_command = state.build_ai_command or build_ai_command
		build_ai_label = state.build_ai_label or build_ai_label
	end

	function api.float_toggle_api_select()
		float_api_select_enabled = not float_api_select_enabled
		vim.notify("Float API Select: " .. (float_api_select_enabled and "ON" or "OFF"), vim.log.levels.INFO)
	end

	local function get_open_positions()
		local positions = {}
		for _, state in pairs(float_terminals) do
			if state.win and vim.api.nvim_win_is_valid(state.win) then
				local cfg = vim.api.nvim_win_get_config(state.win)
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
			if col < 1 then
				col = screen_w - width - 1
			end
			if row > screen_h - height - 4 then
				row = 1
			end
			attempts = attempts + 1
		end

		return row, col
	end

	local function get_float_config(id, kind, tabpage)
		local width = 60
		local height = 16
		local screen_w = vim.o.columns
		local tab_nr = vim.api.nvim_tabpage_get_number(tabpage or vim.api.nvim_get_current_tabpage())
		local configs = {
			term = {
				[1] = { title = " Terminal 1 " },
				[2] = { title = " Terminal 2 " },
				[3] = { title = " Terminal 3 " },
				[4] = { title = " Terminal 4 " },
			},
		}

		local cfg
		if kind == "claude" then
			local profile = ai_float_profiles[id] or {}
			cfg = vim.tbl_extend("force", {
				title = build_ai_label and build_ai_label(profile.provider, profile.api, profile.label) or " AI ",
				cwd = profile.cwd,
			}, profile)
		else
			cfg = (configs[kind] or {})[id] or { title = " Float " .. id }
		end
		local row, col = find_free_position(1, screen_w - width - 1, width, height)
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

		local spec = terminal.normalize_spec(cmd_fn())
		if cfg.cwd and not spec.cwd then
			spec.cwd = cfg.cwd
		end
		terminal.termopen(spec, {
			on_exit = function()
				if float_terminals[key] then
					float_terminals[key].buf = nil
				end
			end,
		})
		vim.cmd("startinsert")

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
			if not choice then
				return
			end
			local api_num = choice == "API 1" and 1 or (choice == "API 2" and 2 or nil)
			callback(api_num)
		end)
	end

	local function float_toggle(id, kind)
		local tabpage = vim.api.nvim_get_current_tabpage()
		local key = string.format("tab_%d_%s_%s", tabpage, kind, id)
		local state = float_terminals[key]

		if state and state.win and vim.api.nvim_win_is_valid(state.win) then
			vim.api.nvim_win_close(state.win, true)
			float_terminals[key].win = nil
			return
		end

		local cfg = get_float_config(id, kind, tabpage)
		if not state or not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
			if kind == "claude" then
				local profile = ai_float_profiles[id] or {}
				if profile.provider and build_ai_command then
					create_float_terminal(key, function()
						return build_ai_command(profile.provider, profile.api, profile.auto_accept)
					end, cfg)
					return
				end
			end
			if kind == "claude" and float_api_select_enabled then
				select_api_and_run(function(api_num)
					create_float_terminal(key, function()
						return build_ai_command("claude", api_num and tostring(api_num) or nil)
					end, cfg)
				end)
			elseif kind == "claude" then
				create_float_terminal(key, function()
					return build_ai_command("claude")
				end, cfg)
			else
				create_float_terminal(key, function()
					return vim.o.shell
				end, cfg)
			end
		else
			reopen_float_window(key, cfg)
		end
	end

	function api.ai_toggle_float_profile(id)
		float_toggle(id, "claude")
	end

	function api.claude_float_1_toggle() api.ai_toggle_float_profile(1) end
	function api.claude_float_2_toggle() api.ai_toggle_float_profile(2) end
	function api.claude_float_3_toggle() api.ai_toggle_float_profile(3) end
	function api.claude_float_4_toggle() api.ai_toggle_float_profile(4) end
	function api.claude_float_nvim_toggle() api.ai_toggle_float_profile(5) end
	function api.claude_float_kitty_toggle() api.ai_toggle_float_profile(6) end

	function api.claude_half_screen_toggle()
		local tabpage = vim.api.nvim_get_current_tabpage()
		local key = string.format("tab_%d_claude_half", tabpage)
		local state = float_terminals[key]

		if state and state.win and vim.api.nvim_win_is_valid(state.win) then
			vim.api.nvim_win_close(state.win, true)
			float_terminals[key].win = nil
			return
		end

		local width = math.floor(vim.o.columns * 0.5)
		local cfg = {
			width = width,
			height = vim.o.lines - 4,
			row = 1,
			col = vim.o.columns - width - 1,
			title = " Claude [T" .. vim.api.nvim_tabpage_get_number(tabpage) .. "] ",
		}

		if not state or not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
			create_float_terminal(key, function()
				return build_ai_command("claude")
			end, cfg)
		else
			reopen_float_window(key, cfg)
		end
	end

	function api.term_float_1_toggle() float_toggle(1, "term") end
	function api.term_float_2_toggle() float_toggle(2, "term") end
	function api.term_float_3_toggle() float_toggle(3, "term") end
	function api.term_float_4_toggle() float_toggle(4, "term") end

	function api.claude_float_toggle_all()
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
					if id then
						float_toggle(tonumber(id), "claude")
					end
				end
			end
		end
	end

	function api.term_float_toggle_all()
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
					if id then
						float_toggle(tonumber(id), "term")
					end
				end
			end
		end
	end

	function api.float_hide_all()
		local tabpage = vim.api.nvim_get_current_tabpage()
		local prefix = string.format("tab_%d_", tabpage)
		for key, state in pairs(float_terminals) do
			if key:match("^" .. prefix) and state.win and vim.api.nvim_win_is_valid(state.win) then
				vim.api.nvim_win_close(state.win, true)
				float_terminals[key].win = nil
			end
		end
	end

	return {
		api = api,
		float_terminals = float_terminals,
		create_float_terminal = create_float_terminal,
		reopen_float_window = reopen_float_window,
	}
end

return M
