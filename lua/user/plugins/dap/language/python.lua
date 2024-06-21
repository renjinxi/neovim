local dap_exists, dap = pcall(require, "dap")
local dap_python_exists, dap_python = pcall(require, "dap-python")

if not dap_exists or not dap_python_exists then
	return
end

dap_python.setup()
local configs = {
	{
		type = "python",
		request = "launch",
		name = "My Launch file with args",
		program = "${file}",
		justMyCode = false,
		args = function()
			local args_string = vim.fn.input("Arguments: ")
			return vim.split(args_string, " +")
		end,
		console = "integratedTerminal",
		pythonPath = function()
			local path = vim.fn.input("Python Path: ")
			--return python_path
			return path
		end,
	},
	{
		type = "python",
		request = "launch",
		name = "My Django",
		program = "${file}",
		justMyCode = false,
		django = true,
		args = function()
			local args_string = vim.fn.input("Arguments: ")
			return vim.split(args_string, " +")
		end,
		console = "integratedTerminal",
		pythonPath = function()
			local path = vim.fn.input("Python Path: ")
			--return python_path
			return path
		end,
	},
}

for _, config in ipairs(configs) do
	table.insert(dap.configurations.python, config)
end
