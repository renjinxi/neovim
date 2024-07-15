local common = require("user.config.common")
local function test_all()
	local project_root = common.find_project_root_by_marker("pyproject.toml") or vim.loop.getcwd()
	require("neotest").run.run(project_root)
end

local keymap = {
	{ "<leader>o", group = "Neotest", nowait = false, remap = false },
	{ "<leader>oa", test_all, desc = "Test All", nowait = false, remap = false },
	{
		"<leader>oc",
		"<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<cr>",
		desc = "Test Current File",
		nowait = false,
		remap = false,
	},
	{
		"<leader>od",
		"<cmd>lua require('neotest').run.run({vim.fn.expand('%'), strategy = 'dap'})<cr>",
		desc = "Debug Current File",
		nowait = false,
		remap = false,
	},
	{ "<leader>oe", "<cmd>Neotest output-panel<cr>", desc = "Show Test Result", nowait = false, remap = false },
	{ "<leader>of", "<cmd>Neotest output<cr>", desc = "Show Test Result In Float", nowait = false, remap = false },
	{
		"<leader>os",
		"<cmd>lua require('neotest').summary.toggle()<cr>",
		desc = "summary Toggle",
		nowait = false,
		remap = false,
	},
	{ "<leader>ot", "<cmd>lua require('neotest').stop()<cr>", desc = "Test Stop", nowait = false, remap = false },
}
require("which-key").add(keymap)
