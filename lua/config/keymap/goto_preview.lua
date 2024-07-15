local keymap = {
	{ "<leader>j", group = "goto_preview", nowait = false, remap = false },
	{
		"<leader>jc",
		"<cmd>lua require('goto-preview').close_all_win()<CR>",
		desc = "close all win",
		nowait = false,
		remap = false,
	},
	{
		"<leader>jd",
		"<cmd>lua require('goto-preview').goto_preview_definition()<CR>",
		desc = "Go to definition",
		nowait = false,
		remap = false,
	},
	{
		"<leader>ji",
		"<cmd>lua require('goto-preview').goto_preview_implementation()<CR>",
		desc = "Go to implemention",
		nowait = false,
		remap = false,
	},
	{
		"<leader>jr",
		"<cmd>lua require('goto-preview').goto_preview_references()<CR>",
		desc = "Go to references",
		nowait = false,
		remap = false,
	},
	{
		"<leader>jt",
		"<cmd>lua require('goto-preview').goto_preview_type_definition()<CR>",
		desc = "Go totype definition",
		nowait = false,
		remap = false,
	},
}
require("which-key").add(keymap)
