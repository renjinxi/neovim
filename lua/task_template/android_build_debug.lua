return {
	name = "Android: Build Debug",
	builder = function()
		local cwd = vim.fn.getcwd()
		return {
			cmd = { "./gradlew", "assembleDebug" },
			cwd = cwd,
			components = {
				{ "on_output_quickfix", set_diagnostics = true },
				"on_result_diagnostics",
				"default",
			},
		}
	end,
	condition = {
		callback = function()
			return vim.fn.filereadable("gradlew") == 1 or vim.fn.filereadable("build.gradle") == 1
		end,
	},
}
