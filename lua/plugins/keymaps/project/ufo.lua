local M = {}

local function fold_except_current()
	require("lua.core.keymaps.project.ufo").closeAllFolds()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	--require('ufo').openFold(row)
	local is_foled = vim.fn.foldclosed(row) ~= -1
	if is_foled then
		vim.api.nvim_command(row .. "foldopen")
	end
end

local function foucs_next_fold_code()
	vim.cmd("normal! zc")
	require("lua.core.keymaps.project.ufo").goNextClosedFold()
	vim.cmd("normal! zO")
	vim.cmd("normal! zz")
end

function M.setup()
	local keymap = {
		{ "<leader>z", group = "Ufo Fold", nowait = false, remap = false },
		{
			"<leader>zh",
			":lua require('ufo').goPreviousStartFold()<cr>",
			desc = "Go To Fold Start",
			nowait = false,
			remap = false,
		},
		{ "<leader>zi", foucs_next_fold_code, desc = "Foucs Next Fold Code", nowait = false, remap = false },
		{
			"<leader>zn",
			":lua require('ufo').goNextClosedFold()<cr>",
			desc = "Go To Next Fold",
			nowait = false,
			remap = false,
		},
		{ "<leader>zo", fold_except_current, desc = "Only Open Current Line", nowait = false, remap = false },
		{
			"<leader>zp",
			":lua require('ufo').goPreviousClosedFold()<cr>",
			desc = "Go To Pre Fold",
			nowait = false,
			remap = false,
		},
	}
	require("which-key").add(keymap)
end

return M
