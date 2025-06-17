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
overseer.setup()

-- 自动加载task_template 下lua
local template_dir = vim.fn.stdpath("config") .. "/lua/task_template"
local template_files = vim.fn.glob(template_dir .. "/*.lua", false, true)
for _, template_file in ipairs(template_files) do
	local ok, template_config = pcall(dofile, template_file)
	if ok and template_config then
		overseer.register_template(template_config)  -- 直接注册模板
		print("Loaded template:", template_config.name)
	else
		print("Failed to load template:", template_file)
	end
end

