local dap_go_exists, dap_go = pcall(require, "dap-go")
if not dap_go_exists then
	return
end

-- Go调试配置
dap_go.setup({
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