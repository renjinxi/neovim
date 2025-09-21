local dap = require("dap")

-- JavaScript/TypeScript 调试适配器配置
-- 支持 Node.js 和浏览器调试

-- 获取调试适配器路径
local js_debug_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter"
local debugger_path = js_debug_path .. "/js-debug/src/dapDebugServer.js"

-- Node.js 调试配置
dap.adapters["pwa-node"] = {
	type = "server",
	host = "localhost",
	port = "${port}",
	executable = {
		command = "node",
		args = { debugger_path, "${port}" },
	},
}

-- Chrome 调试配置
dap.adapters["pwa-chrome"] = {
	type = "server",
	host = "localhost",
	port = "${port}",
	executable = {
		command = "node",
		args = { debugger_path, "${port}" },
	},
}

-- 通用配置函数
local function get_js_debug_config()
	return {
		{
			type = "pwa-node",
			request = "launch",
			name = "Launch file (Node.js)",
			program = "${file}",
			cwd = "${workspaceFolder}",
			sourceMaps = true,
		},
		{
			type = "pwa-node",
			request = "launch",
			name = "Launch Project (Node.js)",
			cwd = "${workspaceFolder}",
			runtimeExecutable = "npm",
			runtimeArgs = { "run", "dev" },
			sourceMaps = true,
			resolveSourceMapLocations = {
				"${workspaceFolder}/**",
				"!**/node_modules/**",
			},
		},
		{
			type = "pwa-node",
			request = "attach",
			name = "Attach to Node Process",
			processId = require("dap.utils").pick_process,
			cwd = "${workspaceFolder}",
			sourceMaps = true,
		},
		{
			type = "pwa-chrome",
			request = "launch",
			name = "Launch Chrome (localhost:3000)",
			url = "http://localhost:3000",
			webRoot = "${workspaceFolder}",
			sourceMaps = true,
			protocol = "inspector",
			sourceMapPathOverrides = {
				["webpack:///./*"] = "${webRoot}/*",
				["webpack:///src/*"] = "${webRoot}/src/*",
				["webpack:///*"] = "*",
			},
		},
		{
			type = "pwa-chrome",
			request = "launch",
			name = "Launch Chrome (localhost:5173 - Vite)",
			url = "http://localhost:5173",
			webRoot = "${workspaceFolder}",
			sourceMaps = true,
			sourceMapPathOverrides = {
				["webpack:///./*"] = "${webRoot}/*",
				["webpack:///src/*"] = "${webRoot}/src/*",
				["webpack:///*"] = "*",
			},
		},
		{
			type = "pwa-chrome",
			request = "launch",
			name = "Launch Chrome (custom port)",
			url = function()
				local co = coroutine.running()
				return coroutine.create(function()
					vim.ui.input({
						prompt = "Enter URL: ",
						default = "http://localhost:3000",
					}, function(url)
						if url == nil or url == "" then
							return
						else
							coroutine.resume(co, url)
						end
					end)
				end)
			end,
			webRoot = "${workspaceFolder}",
			sourceMaps = true,
		},
		{
			type = "pwa-chrome",
			request = "attach",
			name = "Attach to Chrome",
			port = 9222,
			webRoot = "${workspaceFolder}",
			sourceMaps = true,
		},
		-- Jest 测试调试
		{
			type = "pwa-node",
			request = "launch",
			name = "Debug Jest Tests",
			runtimeExecutable = "node",
			runtimeArgs = {
				"./node_modules/.bin/jest",
				"--runInBand",
			},
			rootPath = "${workspaceFolder}",
			cwd = "${workspaceFolder}",
			console = "integratedTerminal",
			internalConsoleOptions = "neverOpen",
			sourceMaps = true,
		},
		-- Next.js 调试配置
		{
			type = "pwa-node",
			request = "launch",
			name = "Next.js: debug server-side",
			runtimeExecutable = "npm",
			runtimeArgs = { "run", "dev" },
			cwd = "${workspaceFolder}",
			sourceMaps = true,
			resolveSourceMapLocations = {
				"${workspaceFolder}/**",
				"!**/node_modules/**",
			},
			skipFiles = { "<node_internals>/**", "node_modules/**" },
		},
		{
			type = "pwa-chrome",
			request = "launch",
			name = "Next.js: debug client-side",
			url = "http://localhost:3000",
			webRoot = "${workspaceFolder}",
			sourceMaps = true,
			sourceMapPathOverrides = {
				["webpack:///./*"] = "${webRoot}/*",
				["webpack://_N_E/*"] = "${webRoot}/*",
			},
		},
		-- React Native 调试
		{
			type = "pwa-node",
			request = "attach",
			name = "Attach to React Native",
			program = "${workspaceFolder}/node_modules/react-native/local-cli/cli.js",
			cwd = "${workspaceFolder}",
			sourceMaps = true,
			port = 9229,
		},
	}
end

-- 配置语言
dap.configurations.javascript = get_js_debug_config()
dap.configurations.typescript = get_js_debug_config()
dap.configurations.javascriptreact = get_js_debug_config()
dap.configurations.typescriptreact = get_js_debug_config()

-- 设置断点样式
vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "🟡", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapLogPoint", { text = "📝", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "➡️", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointRejected", { text = "⚠️", texthl = "", linehl = "", numhl = "" })