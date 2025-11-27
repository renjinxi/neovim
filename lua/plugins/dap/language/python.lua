local dap_exists, dap = pcall(require, "dap")
local dap_python_exists, dap_python = pcall(require, "dap-python")

if not dap_exists or not dap_python_exists then
	return
end

-- 延迟初始化函数，避免启动时执行 io.popen
local function setup_python_dap()
	-- 自动检测 Python 路径，优先使用 uv，回退到 venv-selector
	local function get_python_path()
		-- 首先检查 uv 项目
		local handle = io.popen("uv run which python 2>/dev/null")
		if handle then
			local uv_python = handle:read("*a"):gsub("\n", "")
			handle:close()

			if uv_python and uv_python ~= "" and vim.fn.executable(uv_python) == 1 then
				return uv_python
			end
		end

		-- 检查本地虚拟环境
		local venv_paths = { ".venv/bin/python", "venv/bin/python", ".env/bin/python" }
		for _, path in ipairs(venv_paths) do
			if vim.fn.executable(path) == 1 then
				return vim.fn.fnamemodify(path, ":p")
			end
		end

		-- 回退到系统 Python（venv-selector 可以覆盖）
		return vim.fn.exepath("python")
	end

	-- debugpy 使用 Mason 安装的版本，python_path 使用项目环境
	local python_path = get_python_path()
	local debugpy_path = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
	dap_python.setup(debugpy_path, {
		python_path = python_path
	})
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
end

-- 使用 autocmd 懒加载，只在打开 Python 文件时初始化
vim.api.nvim_create_autocmd("FileType", {
	pattern = "python",
	once = true,
	callback = setup_python_dap,
})
