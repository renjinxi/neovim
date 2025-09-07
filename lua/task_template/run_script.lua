return {
	name = "run script",
	builder = function()
		local file = vim.fn.expand("%:p")
		local file_dir = vim.fn.expand("%:p:h")
		local file_name = vim.fn.expand("%:t")
		local cmd = { file }
		if vim.bo.filetype == "go" then
			cmd = { "go", "run", file }
		elseif vim.bo.filetype == "python" then
			cmd = { "uv", "run", file_name }
		end
		return {
			cmd = cmd,
			cwd = vim.bo.filetype == "python" and file_dir or nil,
			components = {
				{ "on_output_quickfix", set_diagnostics = true },
				"on_result_diagnostics",
				"default",
			},
		}
	end,
	condition = {
		filetype = { "sh", "python", "go" },
	},
} 