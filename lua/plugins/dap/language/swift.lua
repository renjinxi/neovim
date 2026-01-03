local dap_exists, dap = pcall(require, "dap")
if not dap_exists then
	return
end

-- Swift 使用 codelldb 适配器 (与 C/C++ 共用)
dap.configurations.swift = {
	{
		name = "Launch",
		type = "codelldb",
		request = "launch",
		program = function()
			-- 默认查找 .build/debug 目录下的可执行文件
			local build_dir = vim.fn.getcwd() .. "/.build/debug/"
			return vim.fn.input("Path to executable: ", build_dir, "file")
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
		args = function()
			local args_string = vim.fn.input("Arguments: ")
			return vim.split(args_string, " +")
		end,
	},
	{
		name = "Attach to process",
		type = "codelldb",
		request = "attach",
		pid = require("dap.utils").pick_process,
		cwd = "${workspaceFolder}",
	},
}
