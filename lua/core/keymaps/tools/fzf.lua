local M = {}	

function M.setup()
	local keymap = {
		{ "<leader>i", group = "FzfLua", nowait = false, remap = false },
		{ "<leader>if", ":FzfLua files<cr>", desc = "Find Files", nowait = false, remap = false },
	{ "<leader>ig", ":FzfLua live_grep<cr>", desc = "Builtin Live Grep", nowait = false, remap = false },
	-- { "<leader>ia", ":FzfLua neoclip<cr>", desc = "NeoClip", nowait = false, remap = false },
	{ "<leader>ib", ":FzfLua buffers<cr>", desc = "Buffers", nowait = false, remap = false },
	{ "<leader>id", ":FzfLua commands<cr>", desc = "Commands", nowait = false, remap = false },
	{ "<leader>ie", ":FzfLua oldfiles<cr>", desc = "Recent Files", nowait = false, remap = false },
	{ "<leader>ih", ":FzfLua help_tags<cr>", desc = "Help Tags", nowait = false, remap = false },
	{ "<leader>ii", ":FzfLua dir live_grep<cr>", desc = "Dir Live Grep", nowait = false, remap = false },
	{ "<leader>ij", ":FzfLua diagnostics<cr>", desc = "Diagnostics", nowait = false, remap = false },
	{
		"<leader>ik",
		"<cmd>lua require('telescope-live-grep-args.shortcuts').grep_word_under_cursor()<cr>",
		desc = "Live Grep",
		nowait = false,
		remap = false,
	},
	{ "<leader>il", ":FzfLua file_browser<cr>", desc = "File Browser", nowait = false, remap = false },
	{ "<leader>im", ":FzfLua marks<cr>", desc = "Marks", nowait = false, remap = false },
	{ "<leader>in", ":FzfLua command_history<cr>", desc = "Command History", nowait = false, remap = false },
	{ "<leader>io", ":FzfLua projects<cr>", desc = "Recent Projects", nowait = false, remap = false },
	{ "<leader>ip", ":FzfLua jumplist<cr>", desc = "Jumplist", nowait = false, remap = false },
	{
		"<leader>ir",
		"<cmd>lua require'telescope'.extensions.project.project{} <cr>",
		desc = "Recent Project History",
		nowait = false,
		remap = false,
	},
	{ "<leader>is", ":FzfLua search_history<cr>", desc = "Search History", nowait = false, remap = false },
	{ "<leader>it", ":FzfLua git_status<cr>", desc = "Git status", nowait = false, remap = false },
	{ "<leader>iu", ":FzfLua dir find_files<cr>", desc = "Dir Find Files", nowait = false, remap = false },
		{ "<leader>iy", ":FzfLua session-lens<cr>", desc = "Session", nowait = false, remap = false },
	}
	require("which-key").add(keymap)
end

return M
