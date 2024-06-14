local status_ok, which_key = pcall(require, "which-key")

if not status_ok then
	return
end

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
	d = {
		name = "Debug",
		--t = { "<cmd> lua require'dap'.toggle_breakpoint()<cr>", "Toggle Breakpoint" },
		C = {
			"<cmd>lua require('persistent-breakpoints.api').set_conditional_breakpoint()<cr>",
			"Conditional Breakpoint",
		},
		E = { "<cmd> lua require'dap'.eval(vim.fn.inpute '[Expression] > ')<cr>", "Evaluate Input" },
		R = { "<cmd> lua require'dap'.run_to_cursor()<cr>", "Run to Cursor" },
		S = { "<cmd> lua require'dap.ui.widgets'.scopes()<cr>", "Scopes" },
		U = { "<cmd> lua require'dapui'.toggle()<cr>", "Toggle UI" },

		as = { EnableAllBreakpoints, "Enable All Breakpoints" },
		at = { DisableAllBreakpoints, "Disable All Breakpoints" },
		b = { "<cmd> lua require'dap'.step_back()<cr>", "Step Back" },
		c = { "<cmd> lua require'dap'.continue()<cr>", "Continue" },
		d = { "<cmd> lua require'dap'.disconnect()<cr>", "Disconnect" },
		e = { "<cmd> lua require'dapui'.eval()<cr>", "Evaluate" },
		g = { "<cmd> lua require'dap'.session()<cr>", "GetSession" },
		h = { "<cmd> lua require'dap.ui.widgets'.hover()<cr>", "Hover Variables" },
		i = { "<cmd> lua require'dap'.step_into()<cr>", "Step Into" },
		l = { "<cmd> lua require('persistent-breakpoints.api').clear_all_breakpoints()<cr>", "Clear All Breakpoint" },
		n = { "<cmd> lua require'dap'.step_over()<cr>", "Step Over" },
		p = { "<cmd> lua require'dap'.pause.toggle()<cr>", "Pause" },
		q = { "<cmd> lua require'dap'.close()<cr>", "Quit" },
		r = { "<cmd> lua require'dap'.repl.toggle()<cr><C-w>H", "Toggle Repl" },
		s = { "<cmd> lua require'dap'.continue()<cr>", "Start" },
		t = { "<cmd>lua require('persistent-breakpoints.api').toggle_breakpoint()<cr>", "Toggle Breakpoint" },
		u = { "<cmd> lua require'dap'.step_out()<cr>", "Step Out" },
		x = { "<cmd> lua require'dap'.terminate()<cr>", "Terminate" },
	},
}

which_key.register(keymap, {
	mode = "n",
	prefix = "<leader>",
	buffer = nil,
	silent = true,
	noremap = true,
	nowait = false,
})

local keymap_v = {
	name = "Debug",
	e = { "<cmd> lua require'dapui'.eval()<cr>", "Evaluate" },
}

which_key.register(keymap_v, {
	mode = "v",
	prefix = "<leader>",
	buffer = nil,
	silent = true,
	noremap = true,
	nowait = false,
})
