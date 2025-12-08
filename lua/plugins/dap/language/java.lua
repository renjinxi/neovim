local dap_exists, dap = pcall(require, "dap")
if not dap_exists then
	return
end

-- ================================
-- Java/Kotlin 调试适配器配置
-- 支持标准 Java 应用和 Android 应用调试
-- ================================

-- Java Debug Adapter 配置
-- 注意: jdtls 会自动配置 java debug adapter, 这里提供额外的配置

dap.configurations.java = {
	{
		type = "java",
		request = "launch",
		name = "Debug (Launch) - Current File",
		mainClass = "${file}",
	},
	{
		type = "java",
		request = "launch",
		name = "Debug (Launch) - Main Class",
		mainClass = function()
			return vim.fn.input("Main class: ", "", "file")
		end,
	},
	{
		type = "java",
		request = "attach",
		name = "Debug (Attach) - Remote",
		hostName = "127.0.0.1",
		port = function()
			return vim.fn.input("Port: ", "5005")
		end,
	},
	-- Android 应用调试配置
	{
		type = "java",
		request = "attach",
		name = "Debug (Attach) - Android App",
		hostName = "127.0.0.1",
		port = 8700, -- Android Studio 默认调试端口
		projectName = function()
			return vim.fn.input("Project name: ", vim.fn.fnamemodify(vim.fn.getcwd(), ":t"))
		end,
	},
}

-- Kotlin 使用相同的配置 (因为编译到 JVM)
dap.configurations.kotlin = dap.configurations.java

-- DAP 自动命令 - 在 Java/Kotlin 文件中自动加载 jdtls 的 DAP 配置
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "java", "kotlin" },
	callback = function()
		local jdtls_dap_ok, jdtls_dap = pcall(require, "jdtls.dap")
		if jdtls_dap_ok then
			-- JDTLS 会自动注册 java debug adapter
			jdtls_dap.setup_dap_main_class_configs()
		end
	end,
})
