local M = {}

function M.setup()
	local keymap = {
		{ "<leader>t", group = "Tree / Tab", nowait = false, remap = false },
		-- NvimTree
		{ "<leader>tt", "<cmd>NvimTreeToggle<cr>", desc = "Toggle Tree", nowait = false, remap = false },
		{ "<leader>tf", "<cmd>NvimTreeFocus<cr>", desc = "Focus Tree", nowait = false, remap = false },
		{ "<leader>tr", "<cmd>NvimTreeFindFile<cr>", desc = "Find current file", nowait = false, remap = false },
		{ "<leader>tc", "<cmd>NvimTreeClose<cr>", desc = "Close Tree", nowait = false, remap = false },
		-- Tab
		{
			"<leader>tn",
			function()
				vim.ui.input({ prompt = "Tab name: " }, function(name)
					if name and name ~= "" then
						vim.t.tab_name = name
						vim.cmd.redrawtabline()
					end
				end)
			end,
			desc = "Rename tab",
			nowait = false,
			remap = false,
		},
		{
			"<leader>tx",
			function()
				vim.t.tab_name = nil
				vim.cmd.redrawtabline()
			end,
			desc = "Clear tab name",
			nowait = false,
			remap = false,
		},
	}
	require("which-key").add(keymap)
end

return M
