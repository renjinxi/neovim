return {
	name = "run script with args",
	builder = function()
		local file = vim.fn.expand("%:p")
		local args = vim.fn.input("Arguments: ")
		
		local cmd = { file }
		if vim.bo.filetype == "go" then
			cmd = { "go", "run", file }
		elseif vim.bo.filetype == "python" then
			cmd = { "python", file }
		elseif vim.bo.filetype == "sh" then
			cmd = { "bash", file }
		end
		
		-- 添加用户输入的参数
		if args and args ~= "" then
			for arg in args:gmatch("%S+") do
				table.insert(cmd, arg)
			end
		end
		
		return {
			cmd = cmd,
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