local M = {}

function M.setup(opts)
	local api = {}
	local terminal = assert(opts.terminal, "terminal_runtime requires terminal")
	local native_terminals = {}

	local function create_float_term(name, cmd, config)
		config = config or {}
		local width = config.width or math.floor(vim.o.columns * 0.8)
		local height = config.height or math.floor(vim.o.lines * 0.8)
		local row = config.row or math.floor((vim.o.lines - height) / 2)
		local col = config.col or math.floor((vim.o.columns - width) / 2)

		local buf = vim.api.nvim_create_buf(false, true)
		local win = vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			width = width,
			height = height,
			row = row,
			col = col,
			style = "minimal",
			border = "rounded",
			title = config.title or (" " .. name .. " "),
			title_pos = "center",
		})

		terminal.termopen(cmd, {
			on_exit = function()
				native_terminals[name] = nil
			end,
		})

		native_terminals[name] = { buf = buf, win = win, type = "float" }
		vim.cmd("startinsert")

		vim.keymap.set("n", "q", function()
			if native_terminals[name] and native_terminals[name].win and vim.api.nvim_win_is_valid(native_terminals[name].win) then
				vim.api.nvim_win_close(native_terminals[name].win, true)
				native_terminals[name].win = nil
			end
		end, { buffer = buf, noremap = true, silent = true })
	end

	local function create_horizontal_term(name, cmd, config)
		config = config or {}
		local height = config.height or 15

		vim.cmd("botright " .. height .. "split")
		local win = vim.api.nvim_get_current_win()
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_win_set_buf(win, buf)

		terminal.termopen(cmd, {
			on_exit = function()
				native_terminals[name] = nil
			end,
		})

		native_terminals[name] = { buf = buf, win = win, type = "horizontal" }
		vim.cmd("startinsert")
	end

	local function create_vertical_term(name, cmd, config)
		config = config or {}
		local width = config.width or math.floor(vim.o.columns * 0.4)

		vim.cmd("botright " .. width .. "vsplit")
		local win = vim.api.nvim_get_current_win()
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_win_set_buf(win, buf)

		terminal.termopen(cmd, {
			on_exit = function()
				native_terminals[name] = nil
			end,
		})

		native_terminals[name] = { buf = buf, win = win, type = "vertical" }
		vim.cmd("startinsert")
	end

	local function create_tab_term(name, cmd)
		vim.cmd("tabnew")
		local buf = vim.api.nvim_get_current_buf()

		terminal.termopen(cmd, {
			on_exit = function()
				native_terminals[name] = nil
			end,
		})

		native_terminals[name] = { buf = buf, type = "tab" }
		vim.cmd("startinsert")
	end

	local function toggle_term(name, cmd, direction, config)
		local state = native_terminals[name]
		if state and state.buf and vim.api.nvim_buf_is_valid(state.buf) then
			if state.win and vim.api.nvim_win_is_valid(state.win) then
				vim.api.nvim_win_close(state.win, true)
				native_terminals[name].win = nil
				return
			end

			if direction == "float" then
				config = config or {}
				local width = config.width or math.floor(vim.o.columns * 0.8)
				local height = config.height or math.floor(vim.o.lines * 0.8)
				local row = config.row or math.floor((vim.o.lines - height) / 2)
				local col = config.col or math.floor((vim.o.columns - width) / 2)
				local win = vim.api.nvim_open_win(state.buf, true, {
					relative = "editor",
					width = width,
					height = height,
					row = row,
					col = col,
					style = "minimal",
					border = "rounded",
					title = config.title or (" " .. name .. " "),
					title_pos = "center",
				})
				native_terminals[name].win = win
				vim.cmd("startinsert")
			elseif direction == "horizontal" then
				config = config or {}
				vim.cmd("botright " .. (config.height or 15) .. "split")
				local win = vim.api.nvim_get_current_win()
				vim.api.nvim_win_set_buf(win, state.buf)
				native_terminals[name].win = win
				vim.cmd("startinsert")
			elseif direction == "vertical" then
				config = config or {}
				vim.cmd("botright " .. (config.width or math.floor(vim.o.columns * 0.4)) .. "vsplit")
				local win = vim.api.nvim_get_current_win()
				vim.api.nvim_win_set_buf(win, state.buf)
				native_terminals[name].win = win
				vim.cmd("startinsert")
			elseif direction == "tab" then
				for _, tabnr in ipairs(vim.api.nvim_list_tabpages()) do
					for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabnr)) do
						if vim.api.nvim_win_get_buf(win) == state.buf then
							vim.api.nvim_set_current_tabpage(tabnr)
							vim.api.nvim_set_current_win(win)
							vim.cmd("startinsert")
							return
						end
					end
				end
				vim.cmd("tabnew")
				vim.api.nvim_win_set_buf(0, state.buf)
				vim.cmd("startinsert")
			end
			return
		end

		if direction == "float" then
			create_float_term(name, cmd, config)
		elseif direction == "horizontal" then
			create_horizontal_term(name, cmd, config)
		elseif direction == "vertical" then
			create_vertical_term(name, cmd, config)
		elseif direction == "tab" then
			create_tab_term(name, cmd)
		end
	end

	function api.terminal_ncdu_toggle()
		toggle_term("ncdu", "ncdu --color dark", "float", { title = " Ncdu " })
	end

	function api.terminal_htop_toggle()
		toggle_term("htop", "htop", "float", { title = " Htop " })
	end

	function api.terminal_ipython_toggle()
		toggle_term("ipython", "ipython", "horizontal")
	end

	function api.terminal_lua_toggle()
		toggle_term("lua", "lua", "horizontal")
	end

	function api.terminal_newterm_toggle()
		local tab_id = vim.api.nvim_get_current_tabpage()
		toggle_term("newterm_tab" .. tab_id, vim.o.shell, "float", { title = " Terminal " })
	end

	function api.terminal_newsboat_toggle()
		toggle_term("newsboat", "newsboat", "tab")
	end

	function api.terminal_newterm_tab()
		toggle_term("newtab", vim.o.shell, "tab")
	end

	function api.terminal_qwen_toggle()
		toggle_term("qwen", "qwen", "vertical")
	end

	return {
		api = api,
		create_float_term = create_float_term,
		create_horizontal_term = create_horizontal_term,
		create_vertical_term = create_vertical_term,
		create_tab_term = create_tab_term,
		toggle_term = toggle_term,
		native_terminals = native_terminals,
	}
end

return M
