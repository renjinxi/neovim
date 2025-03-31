local M = {}

function M.setup()
	-- Python调试配置
	require("dap-python").setup({
		-- 调试器路径
		python_path = vim.fn.exepath("python"),
		-- 调试器配置
		debugger_path = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python",
		-- 调试器选项
		debugger_options = {
			-- 是否使用控制台
			console = "integratedTerminal",
			-- 是否使用虚拟环境
			venv = true,
			-- 是否使用conda环境
			conda = false,
		},
	})

	-- Go调试配置
	require("dap-go").setup({
		-- 调试器路径
		dap_configurations = {
			{
				type = "go",
				name = "Attach",
				mode = "local",
				request = "attach",
				processId = "${command:PickProcess}",
				program = "${fileDirname}",
			},
		},
		-- 调试器选项
		delve = {
			path = "dlv",
			debugAdapter = "legacy",
			-- 是否使用控制台
			console = "integratedTerminal",
			-- 是否使用虚拟环境
			venv = true,
		},
	})
end

return M
