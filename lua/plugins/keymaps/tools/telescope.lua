local M = {}

function M.setup()
	local keymap = {
		{ "<leader>f", group = "Telescope", nowait = false, remap = false },
		{
			"<leader>fF",
			"<cmd>lua require('telescope.builtin').find_files({no_ignore=true, hidden=true})<cr>",
			desc = "Find Files",
			nowait = false,
			remap = false,
		},
		{ "<leader>fG", "<cmd>Telescope live_grep<cr>", desc = "Builtin Live Grep", nowait = false, remap = false },
		{ "<leader>fa", "<cmd>Telescope neoclip<cr>", desc = "NeoClip", nowait = false, remap = false },
		{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers", nowait = false, remap = false },
		{ "<leader>fd", "<cmd>Telescope commands<cr>", desc = "Commands", nowait = false, remap = false },
		{ "<leader>fe", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files", nowait = false, remap = false },
		{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files", nowait = false, remap = false },
		{
			"<leader>fg",
			"<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<cr>",
			desc = "Live Grep",
			nowait = false,
			remap = false,
		},
		{ "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags", nowait = false, remap = false },
		{ "<leader>fi", "<cmd>Telescope dir live_grep<cr>", desc = "Dir Live Grep", nowait = false, remap = false },
		{ "<leader>fj", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics", nowait = false, remap = false },
		{
			"<leader>fk",
			"<cmd>lua require('telescope-live-grep-args.shortcuts').grep_word_under_cursor()<cr>",
			desc = "Live Grep",
			nowait = false,
			remap = false,
		},
		{ "<leader>fl", "<cmd>Telescope file_browser<cr>", desc = "File Browser", nowait = false, remap = false },
		{ "<leader>fm", "<cmd>Telescope marks<cr>", desc = "Marks", nowait = false, remap = false },
		{ "<leader>fn", "<cmd>Telescope command_history<cr>", desc = "Command History", nowait = false, remap = false },
		{ "<leader>fo", "<cmd>Telescope projects<cr>", desc = "Recent Projects", nowait = false, remap = false },
		{ "<leader>fp", "<cmd>Telescope jumplist<cr>", desc = "Jumplist", nowait = false, remap = false },
		{
			"<leader>fr",
			"<cmd>Telescope projects<cr>",
			desc = "Recent Project History",
			nowait = false,
			remap = false,
		},
		{ "<leader>fs", "<cmd>Telescope search_history<cr>", desc = "Search History", nowait = false, remap = false },
		{ "<leader>ft", "<cmd>Telescope git_status<cr>", desc = "Git status", nowait = false, remap = false },
		{ "<leader>fu", "<cmd>Telescope dir find_files<cr>", desc = "Dir Find Files", nowait = false, remap = false },
		{ "<leader>fy", "<cmd>Telescope session-lens<cr>", desc = "Session", nowait = false, remap = false },
	}
	require("which-key").add(keymap)
end

return M
