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
		-- 调试整个包（当前目录）
		{
			type = "go",
			name = "Debug Package",
			request = "launch",
			program = "${fileDirname}",
		},
		-- 调试主程序（项目根目录）
		{
			type = "go",
			name = "Debug Main (project root)",
			request = "launch",
			program = "${workspaceFolder}",
		},
		-- 附加到远程进程
		{
			type = "go",
			name = "Attach remote",
			mode = "remote",
			request = "attach",
		},
		-- 附加到本地进程
		{
			type = "go",
			name = "Attach to Process",
			mode = "local",
			request = "attach",
			processId = require("dap.utils").pick_process,
		},
		-- 调试测试文件
		{
			type = "go",
			name = "Debug test (current file)",
			request = "launch",
			mode = "test",
			program = "${file}",
		},
		-- 调试包中的所有测试
		{
			type = "go",
			name = "Debug test (go.mod)",
			request = "launch",
			mode = "test",
			program = "./${relativeFileDirname}",
		},
	},
	-- 调试测试时的标志
	tests = {
		-- 启用详细输出
		verbose = false,
	},
})