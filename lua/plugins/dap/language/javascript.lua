local dap = require("dap")

-- JavaScript/TypeScript 调试适配器配置
-- 支持 Node.js 和浏览器调试

-- 获取调试适配器路径
local js_debug_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter"
local debugger_path = js_debug_path .. "/js-debug/src/dapDebugServer.js"

-- 用户选择记忆功能
local user_preferences = {
	frontend_folder = nil,
	port = nil,
}

-- 从package.json检测端口
local function detect_dev_port_from_file(package_json_path)
	if vim.fn.filereadable(package_json_path) == 1 then
		local package_content = vim.fn.readfile(package_json_path)
		local package_str = table.concat(package_content, "\n")

		-- 检查是否是 Vite 项目
		if package_str:match('"vite"') then
			return 5173
		elseif package_str:match('"next"') then
			return 3000
		elseif package_str:match('"react%-scripts"') then
			return 3000
		elseif package_str:match('"nuxt"') then
			return 3000
		elseif package_str:match('"vue"') then
			return 8080
		end
	end

	return 5173 -- 默认 Vite 端口
end

-- 使用find命令智能查找项目
local function find_package_json_projects()
	local projects = {}
	local cwd = vim.fn.getcwd()

	-- 使用find命令查找package.json，排除node_modules
	local find_cmd = string.format(
		"find %s -name 'package.json' -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/build/*' 2>/dev/null",
		vim.fn.shellescape(cwd)
	)

	local handle = io.popen(find_cmd)
	if handle then
		for line in handle:lines() do
			local dir = vim.fn.fnamemodify(line, ":h")
			local relative_dir = vim.fn.fnamemodify(dir, ":.")
			local port = detect_dev_port_from_file(line)

			table.insert(projects, {
				path = dir,
				relative = relative_dir == "." and "current" or relative_dir,
				port = port,
				package_json = line,
			})
		end
		handle:close()
	end

	return projects
end

-- 智能检测项目根目录和端口（完全自动，不弹框）
local function detect_project_info()
	local projects = find_package_json_projects()

	if #projects == 0 then
		return ".", 5173, "${workspaceFolder}" -- 默认值
	end

	-- 优先级选择，不弹框确认：
	-- 1. 当前目录有package.json → 选它
	for _, project in ipairs(projects) do
		if project.relative == "current" then
			return ".", project.port, "${workspaceFolder}"
		end
	end

	-- 2. 找到常见前端目录名 → 选它
	local preferred_names = { "frontend", "client", "web", "app", "ui" }
	for _, name in ipairs(preferred_names) do
		for _, project in ipairs(projects) do
			if project.relative == name then
				local webroot = "${workspaceFolder}/" .. project.relative
				return project.relative, project.port, webroot
			end
		end
	end

	-- 3. 选择最短路径的（通常是最顶层的）
	table.sort(projects, function(a, b)
		return #a.relative < #b.relative
	end)

	local project = projects[1]
	local webroot = "${workspaceFolder}/" .. project.relative
	return project.relative, project.port, webroot
end

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
	-- 自动检测项目信息
	local folder, port, webroot = detect_project_info()
	local url = "http://localhost:" .. port

	return {
		{
			type = "pwa-node",
			request = "launch",
			name = "Launch file (Node.js)",
			program = "${file}",
			cwd = webroot,
			sourceMaps = true,
		},
		{
			type = "pwa-node",
			request = "launch",
			name = "Launch Project (Node.js)",
			cwd = webroot,
			runtimeExecutable = "npm",
			runtimeArgs = { "run", "dev" },
			sourceMaps = true,
			resolveSourceMapLocations = {
				webroot .. "/**",
				"!**/node_modules/**",
			},
		},
		{
			type = "pwa-node",
			request = "attach",
			name = "Attach to Node Process",
			processId = require("dap.utils").pick_process,
			cwd = webroot,
			sourceMaps = true,
		},
		{
			type = "pwa-chrome",
			request = "launch",
			name = "Launch Chrome (Auto-detected: " .. url .. ")",
			url = url,
			webRoot = webroot,
			sourceMaps = true,
			protocol = "inspector",
			smartStep = true,
			trace = true,
			resolveSourceMapLocations = {
				webroot .. "/src/**",
				webroot .. "/public/**",
				"!**/node_modules/**",
				"!**/dist/**",
				"!**/build/**",
				"!**/.next/**",
			},
			skipFiles = {
				"**/node_modules/**/*",
				"**/dist/**/*",
				"**/build/**/*",
				"**/@vite/*",
				"**/webpack/**/*",
				"**/.next/**/*",
			},
			sourceMapPathOverrides = {
				["webpack:///./*"] = webroot .. "/*",
				["webpack:///src/*"] = webroot .. "/src/*",
				["webpack:///*"] = "*",
			},
		},
		{
			type = "pwa-chrome",
			request = "launch",
			name = "Launch Chrome (Custom URL)",
			url = function()
				local co = coroutine.running()
				return coroutine.create(function()
					vim.ui.input({
						prompt = "Enter URL: ",
						default = url,
					}, function(input)
						if input == nil or input == "" then
							return
						else
							coroutine.resume(co, input)
						end
					end)
				end)
			end,
			webRoot = webroot,
			sourceMaps = true,
			smartStep = true,
			trace = true,
		},
		{
			type = "pwa-chrome",
			request = "attach",
			name = "Attach to Chrome",
			port = 9222,
			webRoot = webroot,
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
			rootPath = webroot,
			cwd = webroot,
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
			cwd = webroot,
			sourceMaps = true,
			resolveSourceMapLocations = {
				webroot .. "/**",
				"!**/node_modules/**",
			},
			skipFiles = { "<node_internals>/**", "node_modules/**" },
		},
		{
			type = "pwa-chrome",
			request = "launch",
			name = "Next.js: debug client-side",
			url = url,
			webRoot = webroot,
			sourceMaps = true,
			sourceMapPathOverrides = {
				["webpack:///./*"] = webroot .. "/*",
				["webpack://_N_E/*"] = webroot .. "/*",
			},
		},
		-- React Native 调试
		{
			type = "pwa-node",
			request = "attach",
			name = "Attach to React Native",
			program = webroot .. "/node_modules/react-native/local-cli/cli.js",
			cwd = webroot,
			sourceMaps = true,
			port = 9229,
		},
	}
end

-- 配置语言 - 使用懒加载，避免在家目录启动时执行find命令卡顿
-- 参考: https://github.com/mfussenegger/nvim-dap/discussions/810
local function lazy_get_config()
	if not dap.configurations.javascript then
		local config = get_js_debug_config()
		dap.configurations.javascript = config
		dap.configurations.typescript = config
		dap.configurations.javascriptreact = config
		dap.configurations.typescriptreact = config
	end
	return dap.configurations.javascript
end

-- 设置空表，在第一次调试时才真正初始化
dap.configurations.javascript = {}
dap.configurations.typescript = {}
dap.configurations.javascriptreact = {}
dap.configurations.typescriptreact = {}

-- 使用autocmd在打开JS/TS文件时才初始化配置
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
	once = true,
	callback = function()
		lazy_get_config()
	end,
})

