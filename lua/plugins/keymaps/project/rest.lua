local M = {}

function M.setup()
	local keymap = {
		{ "<leader>a", group = "REST Client", nowait = false, remap = false },
		{
			"<leader>ao",
			"<cmd>Rest open<cr>",
			desc = "Open result pane",
			nowait = false,
			remap = false,
		},
		{
			"<leader>aa",
			"<cmd>Rest run<cr>",
			desc = "Run request under cursor",
			nowait = false,
			remap = false,
		},
		{
			"<leader>an",
			"<cmd>Rest run ",
			desc = "Run request with name",
			nowait = false,
			remap = false,
		},
		{
			"<leader>al",
			"<cmd>Rest last<cr>",
			desc = "Run last request",
			nowait = false,
			remap = false,
		},
		{
			"<leader>ag",
			"<cmd>Rest logs<cr>",
			desc = "Edit logs file",
			nowait = false,
			remap = false,
		},
		{
			"<leader>ac",
			"<cmd>Rest cookies<cr>",
			desc = "Edit cookies file",
			nowait = false,
			remap = false,
		},
		{
			"<leader>as",
			"<cmd>Rest env show<cr>",
			desc = "Show dotenv file",
			nowait = false,
			remap = false,
		},
		{
			"<leader>ae",
			"<cmd>Rest env select<cr>",
			desc = "Select env file",
			nowait = false,
			remap = false,
		},
		{
			"<leader>at",
			"<cmd>Rest env set ",
			desc = "Set env file path",
			nowait = false,
			remap = false,
		},
	}

	require("which-key").add(keymap)
end

return M
