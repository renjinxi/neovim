return {
	"jay-babu/mason-nvim-dap.nvim",
	{
		"mfussenegger/nvim-dap",
		config = function()
			require("plugins.dap")
		end,
	},
	"rcarriga/nvim-dap-ui",
	"mfussenegger/nvim-dap-python",
	{
		"leoluz/nvim-dap-go",
		dependencies = "mfussenegger/nvim-dap",
		config = function()
			require("dap-go").setup()
		end,
	},
	"nvim-telescope/telescope-dap.nvim",
	"theHamsta/nvim-dap-virtual-text",
	{
		"Weissle/persistent-breakpoints.nvim",
		cmd = "PersistentBreakpointsToggle",
		config = function()
			require("persistent-breakpoints").setup({
				load_breakpoints_event = { "BufReadPost" },
			})
		end,
	},
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
		},
		cmd = { "NeotestRun", "NeotestSummary" },
		config = function()
			require("plugins.config.neotest")
		end,
	},
	"nvim-neotest/neotest-python",
	{
		"andythigpen/nvim-coverage",
		requires = "nvim-lua/plenary.nvim",
		config = function()
			require("plugins.config.coverage")
		end,
		rocks = { "lua-xmlreader" },
	},
}
