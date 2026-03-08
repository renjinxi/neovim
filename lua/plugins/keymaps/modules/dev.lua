local M = {}

local function get_workspaces_config()
	return require("plugins.config.workspaces")
end

local function get_possession_config()
	return require("plugins.config.possession")
end

local function get_android_config()
	local ok, android = pcall(require, "plugins.config.android")
	return ok and android or nil
end

function M.dap_conditional_breakpoint()
	require("persistent-breakpoints.api").set_conditional_breakpoint()
end

function M.dap_eval_input()
	require("dap").eval(vim.fn.input("[Expression] > "))
end

function M.dap_toggle_ui()
	local dapui = require("dapui")
	local is_open = false
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
		if name:match("DAP") then
			is_open = true
			break
		end
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
	vim.defer_fn(function()
		require("dap").run_last()
	end, 100)
end

function M.dap_enable_all_breakpoints()
	local dap = require("dap")
	for _, bp in pairs(dap.breakpoints) do
		for _, breakpoint in pairs(bp) do
			breakpoint.enabled = true
		end
	end
	dap.refresh_breakpoints()
end

function M.dap_disable_all_breakpoints()
	local dap = require("dap")
	for _, bp in pairs(dap.breakpoints) do
		for _, breakpoint in pairs(bp) do
			breakpoint.enabled = false
		end
	end
	dap.refresh_breakpoints()
end

function M.dap_clear_all_breakpoints()
	require("persistent-breakpoints.api").clear_all_breakpoints()
end

function M.dap_toggle_breakpoint()
	require("persistent-breakpoints.api").toggle_breakpoint()
end

function M.workspace_add_project()
	get_workspaces_config().add_project_to_workspace()
end

function M.workspace_add_project_path()
	vim.ui.input({ prompt = "Project path: ", completion = "dir" }, function(path)
		if path then
			get_workspaces_config().add_project_to_workspace(vim.fn.expand(path))
		end
	end)
end

function M.workspace_remove_project()
	get_workspaces_config().remove_project_from_workspace()
end

function M.workspace_list_projects()
	get_workspaces_config().list_workspace_projects()
end

function M.workspace_switch_root()
	get_workspaces_config().switch_project_root()
end

function M.workspace_search_all()
	get_workspaces_config().search_all_projects()
end

function M.workspace_search_all_hidden()
	get_workspaces_config().search_all_projects_with_hidden()
end

function M.workspace_grep_all()
	get_workspaces_config().grep_all_projects()
end

function M.workspace_grep_all_hidden()
	get_workspaces_config().grep_all_projects_with_hidden()
end

function M.session_save_workspace()
	get_possession_config().save_workspace_session()
end

function M.session_load_workspace()
	get_possession_config().load_workspace_session()
end

function M.session_delete_workspace()
	get_possession_config().delete_workspace_session()
end

function M.session_list_workspace()
	get_possession_config().list_workspace_sessions()
end

function M.session_telescope()
	if pcall(require, "telescope") then
		vim.cmd("Telescope possession")
	else
		vim.cmd("PossessionList")
	end
end

function M.neotest_all()
	local common = require("core.common")
	local project_root = common.find_project_root_by_marker("pyproject.toml") or vim.loop.getcwd()
	require("neotest").run.run(project_root)
end

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

function M.overseer_go_build()
	require("overseer").run_task({ name = "Go Build" })
end

function M.overseer_run_script()
	require("overseer").run_task({ name = "run script" })
end

function M.overseer_run_script_args()
	require("overseer").run_task({ name = "run script with args" })
end

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

function M.android_adb_picker()
	local android = get_android_config()
	if android then
		android.adb_picker()
	end
end

function M.android_gradle_picker()
	local android = get_android_config()
	if android then
		android.gradle_picker()
	end
end

function M.android_show_error_log()
	local android = get_android_config()
	if android then
		android.show_error_log()
	end
end

return M
