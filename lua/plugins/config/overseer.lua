vim.api.nvim_create_user_command("OverseerRestartLast", function()
	local overseer = require("overseer")
	local tasks = overseer.list_tasks({ recent_first = true })
	if vim.tbl_isempty(tasks) then
		vim.notify("No tasks found", vim.log.levels.WARN)
	else
		overseer.run_action(tasks[1], "restart")
	end
end, {})

-- 任务记忆持久化
local cache_dir = vim.fn.stdpath("data") .. "/overseer_cache"
local function get_cache_file()
	local cwd = vim.fn.getcwd()
	local hash = vim.fn.sha256(cwd):sub(1, 16)
	return cache_dir .. "/" .. hash .. ".json"
end

local function load_last_tasks()
	local file = get_cache_file()
	if vim.fn.filereadable(file) == 1 then
		local content = vim.fn.readfile(file)
		if #content > 0 then
			local ok, data = pcall(vim.json.decode, content[1])
			if ok and data.tasks then
				return data.tasks
			end
		end
	end
	return {}
end

local function save_last_tasks(tasks)
	vim.fn.mkdir(cache_dir, "p")
	local file = get_cache_file()
	local data = vim.json.encode({ tasks = tasks, cwd = vim.fn.getcwd() })
	vim.fn.writefile({ data }, file)
end

local overseer = require("overseer")
local render = require("overseer.render")

-- 自定义渲染函数，显示命令和工作目录
local function format_with_cmd(task)
	local ret = {
		render.status_and_name(task),
		render.cmd(task), -- 显示具体命令
	}
	-- 显示工作目录（简化路径）
	if task.cwd then
		local cwd = task.cwd:gsub(vim.env.HOME, "~")
		table.insert(ret, { { "  " .. cwd, "Comment" } })
	end
	vim.list_extend(ret, render.source_lines(task))
	table.insert(ret, render.join(render.duration(task), render.time_since_completed(task, { hl_group = "Comment" })))
	vim.list_extend(ret, render.result_lines(task, { oneline = true }))
	vim.list_extend(ret, render.output_lines(task, { num_lines = 1 }))
	return render.remove_empty_lines(ret)
end

overseer.setup({
	templates = { "builtin", "user", ".nvim" }, -- 添加 .nvim 支持项目级配置
	strategy = "terminal",
	-- 任务列表面板配置 - 底部面板
	task_list = {
		direction = "bottom",
		-- 高度：占50%
		min_height = { 15, 0.3 },
		max_height = { 40, 0.5 },
		-- 宽度：任务列表部分占50%
		min_width = { 60, 0.4 },
		max_width = { 100, 0.5 },
		default_detail = 2,
		render = format_with_cmd, -- 使用自定义渲染
		-- overseer 2.0 使用 keymaps 而不是 bindings
		keymaps = {
			["?"] = "keymap.show_help",
			["g?"] = "keymap.show_help",
			["<CR>"] = "keymap.run_action",
			["o"] = "keymap.open",
			["p"] = "keymap.toggle_preview",
			["<C-f>"] = { "keymap.open", opts = { dir = "float" }, desc = "Open in float" },
			["<C-v>"] = { "keymap.open", opts = { dir = "vsplit" }, desc = "Open in vsplit" },
			["<C-s>"] = { "keymap.open", opts = { dir = "split" }, desc = "Open in split" },
			-- 快捷操作 (注意: start 只对 PENDING 状态任务有效)
			["r"] = { "keymap.run_action", opts = { action = "restart" }, desc = "Restart task" },
			["R"] = { "keymap.run_action", opts = { action = "restart" }, desc = "Restart task" },
			["x"] = { "keymap.run_action", opts = { action = "stop" }, desc = "Stop task" },
			["dd"] = { "keymap.run_action", opts = { action = "dispose" }, desc = "Dispose task" },
			["w"] = { "keymap.run_action", opts = { action = "watch" }, desc = "Watch (restart on save)" },
			["W"] = { "keymap.run_action", opts = { action = "unwatch" }, desc = "Unwatch" },
			-- 导航
			["}"] = "keymap.next_task",
			["{"] = "keymap.prev_task",
			["<C-j>"] = "keymap.scroll_output_down",
			["<C-k>"] = "keymap.scroll_output_up",
			-- 关闭用默认的 q
		},
	},
	-- 浮动窗口样式
	form = {
		border = "rounded",
		win_opts = { winblend = 0 },
	},
	-- 任务输出窗口配置
	task_win = {
		border = "rounded",
		win_opts = { winblend = 0 },
	},
	confirm = {
		border = "rounded",
		win_opts = { winblend = 0 },
	},
	task_launcher = {
		bindings = {
			n = {
				["<Esc>"] = "Cancel",
			},
		},
	},
})

-- 自动加载task_template 下lua
local template_dir = vim.fn.stdpath("config") .. "/lua/task_template"
local template_files = vim.fn.glob(template_dir .. "/*.lua", false, true)
for _, template_file in ipairs(template_files) do
	local ok, template_config = pcall(dofile, template_file)
	if ok and template_config then
		overseer.register_template(template_config) -- 直接注册模板
		-- print("Loaded template:", template_config.name)
	else
		print("Failed to load template:", template_file)
	end
end

-- 多选任务启动器
vim.api.nvim_create_user_command("OverseerRunMulti", function()
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local tmpl = require("overseer.template")

	tmpl.list({ dir = vim.fn.getcwd() }, function(tmpl_list)
		local templates = {}
		for _, t in ipairs(tmpl_list) do
			table.insert(templates, t.name)
		end

		-- 加载上次选择，默认选中
		local last_tasks = load_last_tasks()
		local selected = {}
		for _, name in ipairs(last_tasks) do
			selected[name] = true
		end

		local function make_finder()
			return finders.new_table({
				results = templates,
				entry_maker = function(item)
					local prefix = selected[item] and "● " or "  "
					return { value = item, display = prefix .. item, ordinal = item }
				end,
			})
		end

		pickers
			.new({}, {
				prompt_title = "Run Tasks (Tab 选择, Enter 启动)",
				finder = make_finder(),
				sorter = conf.generic_sorter({}),
				attach_mappings = function(prompt_bufnr, map)
					-- Tab 切换选中并保存到 cache
					map("i", "<Tab>", function()
						local entry = action_state.get_selected_entry()
						if entry then
							local name = entry.value or entry[1]
							if selected[name] then
								selected[name] = nil
							else
								selected[name] = true
							end
							save_last_tasks(vim.tbl_keys(selected))
							local picker = action_state.get_current_picker(prompt_bufnr)
							picker:refresh(make_finder(), { reset_prompt = false })
						end
					end)

					-- Ctrl+o 仅启动当前光标所在任务，不改变 cache
					map("i", "<C-o>", function()
						local entry = action_state.get_selected_entry()
						if entry then
							actions.close(prompt_bufnr)
							local name = entry.value or entry[1]
							overseer.run_task({ name = name })
							vim.notify("Started: " .. name, vim.log.levels.INFO)
						end
					end)

					-- Enter 启动选中的任务
					actions.select_default:replace(function()
						actions.close(prompt_bufnr)
						local to_run = vim.tbl_keys(selected)
						if #to_run == 0 then
							local entry = action_state.get_selected_entry()
							if entry then
								to_run = { entry.value or entry[1] }
							end
						end
						for _, name in ipairs(to_run) do
							overseer.run_task({ name = name })
						end
						if #to_run > 0 then
							vim.notify("Started " .. #to_run .. " task(s)", vim.log.levels.INFO)
						end
					end)
					return true
				end,
			})
			:find()
	end)
end, {})

-- 直接启动上次的任务组合
vim.api.nvim_create_user_command("OverseerRunLast", function()
	local last_tasks = load_last_tasks()
	if #last_tasks == 0 then
		vim.notify("No saved tasks for this directory", vim.log.levels.WARN)
		return
	end
	for _, name in ipairs(last_tasks) do
		overseer.run_task({ name = name })
	end
	vim.notify("Started " .. #last_tasks .. " task(s)", vim.log.levels.INFO)
end, {})
