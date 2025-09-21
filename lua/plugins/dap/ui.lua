local dapui_exists, dapui = pcall(require, "dapui")
if not dapui_exists then
	return
end

-- 保存原始鼠标设置
local original_mouse = vim.o.mouse

-- DAP UI 事件监听
local dap = require("dap")
dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open()
	-- 启用鼠标
	vim.o.mouse = "a"
end
dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
	-- 恢复原始鼠标设置
	vim.o.mouse = original_mouse
end
dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
	-- 恢复原始鼠标设置
	vim.o.mouse = original_mouse
end

-- 设置断点图标的高亮组
vim.api.nvim_set_hl(0, 'DapBreakpoint', { ctermbg = 0, fg = '#ff6b6b', bg = 'NONE' })
vim.api.nvim_set_hl(0, 'DapBreakpointCondition', { ctermbg = 0, fg = '#feca57', bg = 'NONE' })
vim.api.nvim_set_hl(0, 'DapLogPoint', { ctermbg = 0, fg = '#54a0ff', bg = 'NONE' })
vim.api.nvim_set_hl(0, 'DapStopped', { ctermbg = 0, fg = '#5f27cd', bg = 'NONE' })

-- 定义美观的断点图标
vim.fn.sign_define('DapBreakpoint', {
	text='●',
	texthl='DapBreakpoint',
	linehl='',
	numhl='DapBreakpoint'
})
vim.fn.sign_define('DapBreakpointCondition', {
	text='◉',
	texthl='DapBreakpointCondition',
	linehl='',
	numhl='DapBreakpointCondition'
})
vim.fn.sign_define('DapBreakpointRejected', {
	text='○',
	texthl='DapBreakpoint',
	linehl='',
	numhl='DapBreakpoint'
})
vim.fn.sign_define('DapLogPoint', {
	text='◆',
	texthl='DapLogPoint',
	linehl='',
	numhl='DapLogPoint'
})
vim.fn.sign_define('DapStopped', {
	text='▶',
	texthl='DapStopped',
	linehl='DapStopped',
	numhl='DapStopped'
})

-- 确保颜色在切换主题后不会丢失
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	desc = "保持 DAP 断点图标颜色",
	callback = function()
		vim.api.nvim_set_hl(0, 'DapBreakpoint', { ctermbg = 0, fg = '#ff6b6b', bg = 'NONE' })
		vim.api.nvim_set_hl(0, 'DapBreakpointCondition', { ctermbg = 0, fg = '#feca57', bg = 'NONE' })
		vim.api.nvim_set_hl(0, 'DapLogPoint', { ctermbg = 0, fg = '#54a0ff', bg = 'NONE' })
		vim.api.nvim_set_hl(0, 'DapStopped', { ctermbg = 0, fg = '#5f27cd', bg = 'NONE' })
	end
})

dapui.setup({
	icons = {
		expanded = "▾",
		collapsed = "▸",
		current_frame = "▸"
	},
	layouts = {
		{
			elements = {
				-- Elements to include in this layout
				{ id = "scopes", size = 0.25 }, -- Adjusts the height to 25% of the layout area
				{ id = "breakpoints", size = 0.25 },
				{ id = "stacks", size = 0.25 },
				{ id = "watches", size = 0.25 },
			},
			size = 0.3, -- Adjusts the width to 40 columns
			position = "left", -- Position the layout to the left of the Neovim window
		},
		{
			elements = {
				--"repl"
				{ id = "repl", size = 0.7 }, -- Adjusts the height to 25% of the layout area
				{ id = "console", size = 0.3 },
			},
			size = 0.3, -- Adjusts the height to 25% of the Neovim window height
			position = "bottom", -- Position at the bottom
		},
	},
})
