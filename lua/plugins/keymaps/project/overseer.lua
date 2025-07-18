local M = {}

function M.setup()
	local keymap = {
		{ "<leader>r", group = "Overseer", nowait = false, remap = false },
		{ "<leader>rl", ":OverseerRestartLast<cr>", desc = "Restart Last Task", nowait = false, remap = false },
		{ "<leader>ro", ":OverseerQuickAction<cr>", desc = "Quick Action", nowait = false, remap = false },
		{ "<leader>rr", ":OverseerRun<cr>", desc = "Run", nowait = false, remap = false },
		{ "<leader>rg", ":OverseerToggle<cr>", desc = "Toggle", nowait = false, remap = false },
		{ "<leader>rb", function()
			local overseer = require("overseer")
			overseer.run_template({ name = "Go Build" })
		end, desc = "Go Build", nowait = false, remap = false },
		{ "<leader>rs", function()
			local overseer = require("overseer")
			overseer.run_template({ name = "run script" })
		end, desc = "Run Script", nowait = false, remap = false },
		{ "<leader>ra", function()
			local overseer = require("overseer")
			overseer.run_template({ name = "run script with args" })
		end, desc = "Run Script with Args", nowait = false, remap = false },

		-- { "<leader>rd", ":FzfLua commands<cr>", desc = "Commands", nowait = false, remap = false },
		-- { "<leader>re", ":FzfLua oldfiles<cr>", desc = "Recent Files", nowait = false, remap = false },
		-- { "<leader>rh", ":FzfLua help_tags<cr>", desc = "Help Tags", nowait = false, remap = false },
		-- { "<leader>ri", ":FzfLua dir live_grep<cr>", desc = "Dir Live Grep", nowait = false, remap = false },
		-- { "<leader>rj", ":FzfLua diagnostics<cr>", desc = "Diagnostics", nowait = false, remap = false },
		-- {
		-- 	"<leader>rk",
		-- 	"<cmd>lua require('telescope-live-grep-args.shortcuts').grep_word_under_cursor()<cr>",
		-- 	desc = "Live Grep",
		-- 	nowait = false,
		-- 	remap = false,
		-- },
		-- { "<leader>rl", ":FzfLua file_browser<cr>", desc = "File Browser", nowait = false, remap = false },
		-- { "<leader>rm", ":FzfLua marks<cr>", desc = "Marks", nowait = false, remap = false },
		-- { "<leader>rn", ":FzfLua command_history<cr>", desc = "Command History", nowait = false, remap = false },
		-- { "<leader>ro", ":FzfLua projects<cr>", desc = "Recent Projects", nowait = false, remap = false },
		-- { "<leader>rp", ":FzfLua jumplist<cr>", desc = "Jumplist", nowait = false, remap = false },
		-- {
		-- 	"<leader>rr",
		-- 	"<cmd>lua require'telescope'.extensions.project.project{} <cr>",
		-- 	desc = "Recent Project History",
		-- 	nowait = false,
		-- 	remap = false,
		-- },
		-- { "<leader>rs", ":FzfLua search_history<cr>", desc = "Search History", nowait = false, remap = false },
		-- { "<leader>rt", ":FzfLua git_status<cr>", desc = "Git status", nowait = false, remap = false },
		-- { "<leader>ru", ":FzfLua dir find_files<cr>", desc = "Dir Find Files", nowait = false, remap = false },
		-- { "<leader>ry", ":FzfLua session-lens<cr>", desc = "Session", nowait = false, remap = false },
	}
	require("which-key").add(keymap)
end

return M
