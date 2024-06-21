local dapui_exists, dapui = pcall(require, "dapui")
if not dapui_exists then
	return
end

dapui.setup({
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
