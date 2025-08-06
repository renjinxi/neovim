local M = {}

function M.setup()
	local keymap = {
		{ "<leader>r", group = "Overseer", nowait = false, remap = false },
		{ "<leader>rl", ":OverseerRestartLast<cr>", desc = "Restart Last Task", nowait = false, remap = false },
		{ "<leader>ro", ":OverseerQuickAction<cr>", desc = "Quick Action", nowait = false, remap = false },
		{ "<leader>rr", ":OverseerRun<cr>", desc = "Run", nowait = false, remap = false },
		{ "<leader>rg", ":OverseerToggle<cr>", desc = "Toggle", nowait = false, remap = false },
		{
			"<leader>rb",
			function()
				local overseer = require("overseer")
				overseer.run_template({ name = "Go Build" })
			end,
			desc = "Go Build",
			nowait = false,
			remap = false,
		},
		{
			"<leader>rs",
			function()
				local overseer = require("overseer")
				overseer.run_template({ name = "run script" })
			end,
			desc = "Run Script",
			nowait = false,
			remap = false,
		},
		{
			"<leader>ra",
			function()
				local overseer = require("overseer")
				overseer.run_template({ name = "run script with args" })
			end,
			desc = "Run Script with Args",
			nowait = false,
			remap = false,
		},
	}
	require("which-key").add(keymap)
end

return M
