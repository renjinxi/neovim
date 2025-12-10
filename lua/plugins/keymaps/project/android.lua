local M = {}

function M.setup()
	local android = require("plugins.config.android")

	local keymap = {
		{ "<leader>a", group = "Android", nowait = false, remap = false },
		{
			"<leader>ad",
			function()
				android.adb_picker()
			end,
			desc = "ADB Commands",
			nowait = false,
			remap = false,
		},
		{
			"<leader>ag",
			function()
				android.gradle_picker()
			end,
			desc = "Gradle Tasks",
			nowait = false,
			remap = false,
		},
		{
			"<leader>al",
			function()
				android.show_error_log()
			end,
			desc = "View Error Log",
			nowait = false,
			remap = false,
		},
	}
	require("which-key").add(keymap)
end

return M
