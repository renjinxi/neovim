local dap = require("dap")

local function DisableAllBreakpoints()
	for _, bp in pairs(dap.breakpoints) do
		for _, breakpoint in pairs(bp) do
			breakpoint.enabled = false
		end
	end
	dap.refresh_breakpoints()
end

local function EnableAllBreakpoints()
	for _, bp in pairs(dap.breakpoints) do
		for _, breakpoint in pairs(bp) do
			breakpoint.enabled = true
		end
	end
	dap.refresh_breakpoints()
end

local keymap = {
	{ "<leader>d", group = "Debug", nowait = false, remap = false },
	{
		"<leader>dC",
		"<cmd>lua require('persistent-breakpoints.api').set_conditional_breakpoint()<cr>",
		desc = "Conditional Breakpoint",
		nowait = false,
		remap = false,
	},
	{
		"<leader>dE",
		"<cmd> lua require'dap'.eval(vim.fn.inpute '[Expression] > ')<cr>",
		desc = "Evaluate Input",
		nowait = false,
		remap = false,
	},
	{
		"<leader>dR",
		"<cmd> lua require'dap'.run_to_cursor()<cr>",
		desc = "Run to Cursor",
		nowait = false,
		remap = false,
	},
	{ "<leader>dS", "<cmd> lua require'dap.ui.widgets'.scopes()<cr>", desc = "Scopes", nowait = false, remap = false },
	{ "<leader>dU", "<cmd> lua require'dapui'.toggle()<cr>", desc = "Toggle UI", nowait = false, remap = false },
	{ "<leader>das", EnableAllBreakpoints, desc = "Enable All Breakpoints", nowait = false, remap = false },
	{ "<leader>dat", DisableAllBreakpoints, desc = "Disable All Breakpoints", nowait = false, remap = false },
	{ "<leader>db", "<cmd> lua require'dap'.step_back()<cr>", desc = "Step Back", nowait = false, remap = false },
	{ "<leader>dc", "<cmd> lua require'dap'.continue()<cr>", desc = "Continue", nowait = false, remap = false },
	{ "<leader>dd", "<cmd> lua require'dap'.disconnect()<cr>", desc = "Disconnect", nowait = false, remap = false },
	{ "<leader>de", "<cmd> lua require'dapui'.eval()<cr>", desc = "Evaluate", nowait = false, remap = false },
	{ "<leader>dg", "<cmd> lua require'dap'.session()<cr>", desc = "GetSession", nowait = false, remap = false },
	{
		"<leader>dh",
		"<cmd> lua require'dap.ui.widgets'.hover()<cr>",
		desc = "Hover Variables",
		nowait = false,
		remap = false,
	},
	{ "<leader>di", "<cmd> lua require'dap'.step_into()<cr>", desc = "Step Into", nowait = false, remap = false },
	{
		"<leader>dl",
		"<cmd> lua require('persistent-breakpoints.api').clear_all_breakpoints()<cr>",
		desc = "Clear All Breakpoint",
		nowait = false,
		remap = false,
	},
	{ "<leader>dn", "<cmd> lua require'dap'.step_over()<cr>", desc = "Step Over", nowait = false, remap = false },
	{ "<leader>dp", "<cmd> lua require'dap'.pause.toggle()<cr>", desc = "Pause", nowait = false, remap = false },
	{ "<leader>dq", "<cmd> lua require'dap'.close()<cr>", desc = "Quit", nowait = false, remap = false },
	{
		"<leader>dr",
		"<cmd> lua require'dap'.repl.toggle()<cr><C-w>H",
		desc = "Toggle Repl",
		nowait = false,
		remap = false,
	},
	{ "<leader>ds", "<cmd> lua require'dap'.continue()<cr>", desc = "Start", nowait = false, remap = false },
	{
		"<leader>dt",
		"<cmd>lua require('persistent-breakpoints.api').toggle_breakpoint()<cr>",
		desc = "Toggle Breakpoint",
		nowait = false,
		remap = false,
	},
	{ "<leader>du", "<cmd> lua require'dap'.step_out()<cr>", desc = "Step Out", nowait = false, remap = false },
	{ "<leader>dx", "<cmd> lua require'dap'.terminate()<cr>", desc = "Terminate", nowait = false, remap = false },
}
require("which-key").add(keymap)

local keymap_v = {
	{ "<leader>", group = "Debug", mode = "v", nowait = false, remap = false },
	{
		"<leader>e",
		"<cmd> lua require'dapui'.eval()<cr>",
		desc = "Evaluate",
		mode = "v",
		nowait = false,
		remap = false,
	},
}
require("which-key").add(keymap_v)
