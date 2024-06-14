local normal_opts = {
	mode = "n",
	prefix = "<leader>",
	buffer = nil,
	silent = true,
	noremap = true,
	nowait = false,
}

local function fold_except_current()
	require("ufo").closeAllFolds()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	--require('ufo').openFold(row)
	local is_foled = vim.fn.foldclosed(row) ~= -1
	if is_foled then
		vim.api.nvim_command(row .. "foldopen")
	end
end

local function foucs_next_fold_code()
	vim.cmd("normal! zc")
	require("ufo").goNextClosedFold()
	vim.cmd("normal! zO")
	vim.cmd("normal! zz")
end

local keymap = {
	z = {
		name = "Ufo Fold",
		o = { fold_except_current, "Only Open Current Line" },
		i = { foucs_next_fold_code, "Foucs Next Fold Code" },
		n = { ":lua require('ufo').goNextClosedFold()<cr>", "Go To Next Fold" },
		p = { ":lua require('ufo').goPreviousClosedFold()<cr>", "Go To Pre Fold" },
		h = { ":lua require('ufo').goPreviousStartFold()<cr>", "Go To Fold Start" },
	},
}

require("which-key").register(keymap, normal_opts)
