-- Claude Code 终端按键映射
-- 使用内置终端，简单干净

local M = {}

function M.setup()
	local keymap = {
		{ "<leader>c", group = "Claude Code", nowait = false, remap = false },
		{
			"<leader>cc",
			function()
				vim.cmd("vsplit | terminal claude")
			end,
			desc = "打开 Claude Code 终端",
			nowait = false,
			remap = false,
		},
	}
	
	require("which-key").add(keymap)
end

return M