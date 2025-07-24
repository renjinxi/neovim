local M = {}

function M.setup()
	local keymap = {
		{ "<leader>b", group = "Messages", nowait = false, remap = false },
		{
			"<leader>ba",
			"<cmd>messages<CR>",
			desc = "All Messages",
			nowait = false,
			remap = false,
		},
		{
			"<leader>bl",
			"<cmd>echo v:statusmsg<CR>",
			desc = "Last Message",
			nowait = false,
			remap = false,
		},
	}
	require("which-key").add(keymap)
end

return M