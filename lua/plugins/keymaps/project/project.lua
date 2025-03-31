local M = {}

function M.setup()
	local keymap = {
		{ "<leader>p", group = "Project", nowait = false, remap = false },
		{ "<leader>pp", "<cmd>Telescope projects<cr>", desc = "List Projects", nowait = false, remap = false },
		{
			"<leader>pf",
			"<cmd>Telescope find_files<cr>",
			desc = "Find Files in Project",
			nowait = false,
			remap = false,
		},
		{ "<leader>ps", "<cmd>Telescope live_grep<cr>", desc = "Search in Project", nowait = false, remap = false },
		{
			"<leader>pr",
			function()
				-- 重新检测项目根目录
				require("project_nvim.project").set_pwd()
			end,
			desc = "Reset Project Root",
			nowait = false,
			remap = false,
		},
		{
			"<leader>pm",
			function()
				-- 手动设置项目根目录
				vim.ui.input({ prompt = "Enter project root path: " }, function(input)
					if input then
						vim.cmd("cd " .. input)
						require("project_nvim.project").set_pwd()
					end
				end)
			end,
			desc = "Manually Set Project Root",
			nowait = false,
			remap = false,
		},
	}

	require("which-key").add(keymap)
end

return M
