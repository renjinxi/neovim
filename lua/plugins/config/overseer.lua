vim.api.nvim_create_user_command("OverseerRestartLast", function()
	local overseer = require("overseer")
	local tasks = overseer.list_tasks({ recent_first = true })
	if vim.tbl_isempty(tasks) then
		vim.notify("No tasks found", vim.log.levels.WARN)
	else
		overseer.run_action(tasks[1], "restart")
	end
end, {})

local overseer = require("overseer")
overseer.setup({
	templates = { "builtin", "user" },
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
		bindings = {
			["<CR>"] = "RunAction",
			["o"] = "Open",
			["<C-f>"] = "OpenFloat", -- 浮动窗口查看输出
			["r"] = "Restart",
			["d"] = "Dispose",
			["q"] = "Close",
			["<Esc>"] = "Close",
		},
	},
	-- 浮动窗口样式
	form = {
		border = "rounded",
		win_opts = { winblend = 0 },
	},
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
