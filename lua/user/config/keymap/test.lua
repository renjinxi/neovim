local common = require("user.config.common")
local normal_opts = {
	mode = "n",
	prefix = "<leader>",
	buffer = nil,
	silent = true,
	noremap = true,
	nowait = false,
}

local function test_all()
	local project_root = common.find_project_root_by_marker("pyproject.toml") or vim.loop.getcwd()
	require("neotest").run.run(project_root)
end

local keymap = {
	o = {
		name = "Neotest",
		--d = { "<cmd>lua require('neotest').diagnostics()<cr>", "Show Test Diagnostics" },
		--s = { "<cmd>lua require('neotest').status.toggle()<cr>", "Status Toggle" },
		a = { test_all, "Test All" },
		c = { "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<cr>", "Test Current File" },
		d = { "<cmd>lua require('neotest').run.run({vim.fn.expand('%'), strategy = 'dap'})<cr>", "Debug Current File" },
		e = { "<cmd>Neotest output-panel<cr>", "Show Test Result" },
		f = { "<cmd>Neotest output<cr>", "Show Test Result In Float" },
		s = { "<cmd>lua require('neotest').summary.toggle()<cr>", "summary Toggle" },
		t = { "<cmd>lua require('neotest').stop()<cr>", "Test Stop" },
	},
}
require("which-key").register(keymap, normal_opts)
