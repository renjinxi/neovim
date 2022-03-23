local status_ok, picker = pcall("window-picker")
if not status_ok then
	return
end

picker.setup({
	autoselect_one = true,
	include_current = false,
	filter_rules = {
		bo = {
			filetype = { "neo-tree", "neo-tree-popup", "notify", "quickfix" },
			buftype = { "terminal" },
		},
	},
	other_win_hl_color = "#e35e4f",
})

local function pick_window()
	local picked_window_id = picker.pick_window({
		include_current_win = true,
	}) or vim.api.nvim_get_current_win()
	vim.api.nvim_set_current_win(picked_window_id)
end

-- Swap two windows using the awesome window picker
local function swap_windows()
	local window = picker.pick_window({
		include_current_win = false,
	})
	local target_buffer = vim.fn.winbufnr(window)
	-- Set the target window to contain current buffer
	vim.api.nvim_win_set_buf(window, 0)
	-- Set current window to contain target buffer
	vim.api.nvim_win_set_buf(0, target_buffer)
end

vim.keymap.set("n", "<leader>wf", pick_window, { desc = "Pick windows" })
vim.keymap.set("n", "<leader>ws", swap_windows, { desc = "Swap windows" })(
	--local status_ok, which_key = pcall("which-key")

	--if not status_ok then
	--return
	--end

	--local keymap = {
	--k = {
	--name = "Picker Window",
	--f = {pick_window, "Pick"},
	--s = {swap_windows, "Swap"},
	--}
	--}

	--which_key.register(keymap, {
	--mode = "n",
	--prefix = "<leader>",
	--buffer = nil,
	--silent =  true,
	--noremap = true,
	--nowait = false,
	--})

	{
		"s1n7ax/nvim-window-picker",
		lazy = true,
		event = { "WinNew" },
		config = function()
			local picker = require("window-picker")
			picker.setup({
				autoselect_one = true,
				include_current = false,
				filter_rules = {
					bo = {
						filetype = { "neo-tree", "neo-tree-popup", "notify", "quickfix" },
						buftype = { "terminal" },
					},
				},
				other_win_hl_color = "#e35e4f",
			})

			vim.keymap.set("n", "<leader>wf", function()
				local picked_window_id = picker.pick_window({
					include_current_win = true,
				}) or vim.api.nvim_get_current_win()
				vim.api.nvim_set_current_win(picked_window_id)
			end, { desc = "Pick a window" })

			-- Swap two windows using the awesome window picker
			local function swap_windows()
				local window = picker.pick_window({
					include_current_win = false,
				})
				local target_buffer = vim.fn.winbufnr(window)
				-- Set the target window to contain current buffer
				vim.api.nvim_win_set_buf(window, 0)
				-- Set current window to contain target buffer
				vim.api.nvim_win_set_buf(0, target_buffer)
			end

			vim.keymap.set("n", "<leader>ws", swap_windows, { desc = "Swap windows" })
		end,
	}
)
