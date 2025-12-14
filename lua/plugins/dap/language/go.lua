local dap_go_exists, dap_go = pcall(require, "dap-go")
if not dap_go_exists then
	return
end

-- Go调试配置
dap_go.setup({
	-- delve 配置
	delve = {
		-- delve 路径 (Mason 安装的路径)
		path = vim.fn.stdpath("data") .. "/mason/bin/dlv",
		-- 初始化超时
		initialize_timeout_sec = 20,
		-- delve 端口
		port = "${port}",
		-- 构建标志
		build_flags = "",
	},
	-- 额外的dap配置 (可选)
	dap_configurations = {
		-- 调试当前单个文件
		{
			type = "go",
			name = "Debug Current File",
			request = "launch",
			program = "${file}",
		},
		-- 调试当前包（当前目录）
		{
			type = "go",
			name = "Debug Package",
			request = "launch",
			program = "${fileDirname}",
		},
		-- 调试当前包（带固定配置文件参数）
		{
			type = "go",
			name = "Debug Package with Config",
			request = "launch",
			program = "${fileDirname}",
			args = { "-c", "./conf/config.yaml" },
		},
		-- 调试当前包（动态输入参数）
		{
			type = "go",
			name = "Debug Package with Args",
			request = "launch",
			program = "${fileDirname}",
			args = function()
				local args_string = vim.fn.input("Arguments: ", "-c ./conf/config.yaml")
				return vim.split(args_string, " +")
			end,
		},
		-- 调试当前测试文件
		{
			type = "go",
			name = "Debug Test File",
			request = "launch",
			mode = "test",
			program = "${file}",
		},
		-- 附加到已运行的本地进程
		{
			type = "go",
			name = "Attach to Process",
			mode = "local",
			request = "attach",
			processId = require("dap.utils").pick_process,
		},
	},
	-- 调试测试时的标志
	tests = {
		-- 启用详细输出
		verbose = false,
	},
})
