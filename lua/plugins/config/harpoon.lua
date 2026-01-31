-- ================================
-- Harpoon2 快速文件标记和跳转（项目级别，支持跨 tab 跳转）
-- ================================

local harpoon = require("harpoon")

-- 自定义跳转函数：优先跳到已打开的 tab/window
local function select_with_tab(list_item, list, options)
	if not list_item then return end
	local file = list_item.value

	-- 遍历所有 tab 和 window，找到已打开该文件的窗口
	for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
			local buf = vim.api.nvim_win_get_buf(win)
			local buf_name = vim.api.nvim_buf_get_name(buf)
			if buf_name == file or buf_name == vim.fn.fnamemodify(file, ":p") then
				vim.api.nvim_set_current_tabpage(tab)
				vim.api.nvim_set_current_win(win)
				return
			end
		end
	end

	-- 没找到已打开的窗口，用 tab drop
	vim.cmd("tab drop " .. vim.fn.fnameescape(file))
end

harpoon:setup({
	settings = {
		save_on_toggle = true,
		sync_on_ui_close = true,
	},
	default = {
		select = select_with_tab,
	},
})

-- 快捷键
vim.keymap.set("n", "<leader>ha", function() harpoon:list():add() end, { desc = "Harpoon: add" })
vim.keymap.set("n", "<leader>hh", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon: menu" })
vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end, { desc = "Harpoon 1" })
vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end, { desc = "Harpoon 2" })
vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end, { desc = "Harpoon 3" })
vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end, { desc = "Harpoon 4" })
