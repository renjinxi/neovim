return {
	name = "Go Build",
	builder = function()
		local file = vim.fn.expand("%:p")
		local dir = vim.fn.expand("%:p:h")
		return {
			cmd = { "go", "build", "-v", "." },
			cwd = dir,
			components = {
				{ "on_output_quickfix", set_diagnostics = true },
				"on_result_diagnostics",
				"default",
			},
		}
	end,
	condition = {
		filetype = { "go" },
	},
}