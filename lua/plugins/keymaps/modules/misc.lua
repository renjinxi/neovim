local M = {}

function M.setup(opts)
	local api = {}
	local float_terminals = assert(opts.float_terminals, "misc module requires float_terminals")
	local create_float_terminal = assert(opts.create_float_terminal, "misc module requires create_float_terminal")
	local reopen_float_window = assert(opts.reopen_float_window, "misc module requires reopen_float_window")

	function api.terminal_scroll_up()
		vim.cmd([[stopinsert]])
		vim.schedule(function()
			local half_page = math.floor(vim.api.nvim_win_get_height(0) / 2)
			vim.cmd("normal! " .. half_page .. "k")
		end)
	end

	function api.nvim_tree_float()
		local view = require("nvim-tree.view")
		local nvim_tree = require("nvim-tree.api")

		nvim_tree.tree.close()

		local width = math.floor(vim.o.columns * 0.6)
		local height = math.floor(vim.o.lines * 0.7)
		local col = math.floor((vim.o.columns - width) / 2)
		local row = math.floor((vim.o.lines - height) / 2)

		view.View.float.enable = true
		view.View.float.open_win_config = {
			relative = "editor",
			width = width,
			height = height,
			col = col,
			row = row,
			border = "rounded",
		}

		nvim_tree.tree.open()
		vim.schedule(function()
			view.View.float.enable = false
		end)

		local bufnr = vim.api.nvim_get_current_buf()
		vim.keymap.set("n", "<CR>", function()
			local node = nvim_tree.tree.get_node_under_cursor()
			nvim_tree.node.open.edit()
			if not (node and node.type == "directory") then
				nvim_tree.tree.close()
			end
		end, { buffer = bufnr, nowait = true })
	end

	function api.mail_aerc()
		local tabpage = vim.api.nvim_get_current_tabpage()
		local key = string.format("tab_%d_mail_aerc", tabpage)
		local state = float_terminals[key]

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
			create_float_terminal(key, function()
				return "aerc"
			end, cfg)
		else
			reopen_float_window(key, cfg)
		end
	end

	function api.open_daily_note()
		local date_str = os.date("%Y-%m-%d")
		local notes_dir = vim.fn.expand("~/.ai/journal/daily")
		local file_path = notes_dir .. "/" .. date_str .. ".md"
		vim.fn.mkdir(notes_dir, "p")

		local width = math.floor(vim.o.columns * 0.7)
		local height = math.floor(vim.o.lines * 0.7)
		local row = math.floor((vim.o.lines - height) / 2)
		local col = math.floor((vim.o.columns - width) / 2)

		local buf = vim.fn.bufnr(file_path, true)
		vim.fn.bufload(buf)
		vim.bo[buf].buflisted = true

		local win = vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			width = width,
			height = height,
			row = row,
			col = col,
			style = "minimal",
			border = "rounded",
			title = " Daily: " .. date_str .. " ",
			title_pos = "center",
		})

		vim.keymap.set("n", "q", function()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, false)
			end
		end, { buffer = buf, noremap = true, silent = true })
	end

	function api.goto_global_mark(mark)
		local info = vim.api.nvim_get_mark(mark, {})
		if info[1] == 0 then
			vim.notify("Mark " .. mark .. " not set", vim.log.levels.WARN)
			return
		end
		local file = info[4]
		if file == "" then
			vim.cmd("normal! '" .. mark)
			return
		end
		vim.cmd("tab drop " .. vim.fn.fnameescape(file))
		vim.api.nvim_win_set_cursor(0, { info[1], info[2] })
	end

	function api.setup_global_mark_keymaps()
		for i = 65, 90 do
			local mark = string.char(i)
			vim.keymap.set("n", "'" .. mark, function()
				api.goto_global_mark(mark)
			end, { desc = "Jump to mark " .. mark })
		end
	end

	function api.clipboard_multi_paste()
		local ok, yanky_history = pcall(require, "yanky.history")
		if not ok then
			vim.notify("yanky not loaded", vim.log.levels.ERROR)
			return
		end

		local history = yanky_history.all()
		if #history == 0 then
			vim.notify("剪贴板历史为空", vim.log.levels.WARN)
			return
		end

		local pickers = require("telescope.pickers")
		local finders = require("telescope.finders")
		local conf = require("telescope.config").values
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")

		local entries = {}
		for i, item in ipairs(history) do
			local text = item.regcontents or ""
			local preview = text:gsub("\n", "\\n"):sub(1, 80)
			table.insert(entries, { idx = i, text = text, preview = preview })
		end

		pickers.new({}, {
			prompt_title = "剪贴板历史 (Tab 多选, Enter 拼接粘贴)",
			finder = finders.new_table({
				results = entries,
				entry_maker = function(entry)
					return {
						value = entry,
						display = string.format("%d: %s", entry.idx, entry.preview),
						ordinal = entry.preview,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local picker = action_state.get_current_picker(prompt_bufnr)
					local selections = picker:get_multi_selection()
					if #selections == 0 then
						local entry = action_state.get_selected_entry()
						if entry then
							selections = { entry }
						end
					end

					actions.close(prompt_bufnr)
					if #selections == 0 then
						return
					end

					table.sort(selections, function(a, b)
						return a.value.idx < b.value.idx
					end)
					local parts = {}
					for _, sel in ipairs(selections) do
						table.insert(parts, sel.value.text)
					end
					local result = table.concat(parts, "\n")

					vim.fn.setreg("+", result)
					vim.api.nvim_put(vim.split(result, "\n"), "l", true, true)
					vim.notify(string.format("已拼接 %d 条记录并粘贴", #selections))
				end)
				return true
			end,
		}):find()
	end

	return api
end

return M
