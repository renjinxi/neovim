-- ================================
-- JDTLS (Java Language Server) 配置
-- 支持 Java 和 Kotlin 开发，特别优化 Android 项目
-- ================================

local M = {}

function M.setup()
	local jdtls_ok, jdtls = pcall(require, "jdtls")
	if not jdtls_ok then
		-- nvim-jdtls 未安装，使用默认 LSP
		return
	end

	-- 检查 Mason registry 是否可用
	local mason_ok, mason_registry = pcall(require, "mason-registry")
	if not mason_ok then
		vim.notify("Mason 未安装", vim.log.levels.WARN)
		return
	end

	-- 检查 jdtls 包是否已安装
	if not mason_registry.is_installed("jdtls") then
		vim.notify("jdtls 未安装，请运行 :MasonInstall jdtls", vim.log.levels.WARN)
		return
	end

	-- 获取环境变量
	local env = require("core.env")
	local java_home = env.get("JAVA_HOME") or os.getenv("JAVA_HOME") or "/usr/lib/jvm/default-java"
	local android_home = env.get("ANDROID_HOME") or os.getenv("ANDROID_HOME") or ""

	-- JDTLS 安装路径 (Mason 安装)
	local jdtls_path = mason_registry.get_package("jdtls"):get_install_path()

	-- 配置和插件路径
	local config_path = jdtls_path .. "/config_linux"
	if vim.fn.has("mac") == 1 then
		config_path = jdtls_path .. "/config_mac"
	elseif vim.fn.has("win32") == 1 then
		config_path = jdtls_path .. "/config_win"
	end

	-- Lombok 支持
	local lombok_path = jdtls_path .. "/lombok.jar"

	-- 项目工作区数据目录 (每个项目独立)
	local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
	local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. project_name

	-- Java Debug 和 Test 插件路径
	local bundles = {}

	-- Java Debug Adapter (可选)
	if mason_registry.is_installed("java-debug-adapter") then
		local java_debug_path = mason_registry.get_package("java-debug-adapter"):get_install_path()
		local java_debug_jar =
			vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar", true)
		if java_debug_jar ~= "" then
			table.insert(bundles, java_debug_jar)
		end
	end

	-- Java Test Runner (可选)
	if mason_registry.is_installed("java-test") then
		local java_test_path = mason_registry.get_package("java-test"):get_install_path()
		local java_test_jars = vim.split(vim.fn.glob(java_test_path .. "/extension/server/*.jar", true), "\n")
		for _, jar in ipairs(java_test_jars) do
			if jar ~= "" then
				table.insert(bundles, jar)
			end
		end
	end

	-- LSP 配置
	local config = {
		cmd = {
			java_home .. "/bin/java",
			"-Declipse.application=org.eclipse.jdt.ls.core.id1",
			"-Dosgi.bundles.defaultStartLevel=4",
			"-Declipse.product=org.eclipse.jdt.ls.core.product",
			"-Dlog.protocol=true",
			"-Dlog.level=ALL",
			"-Xmx1g",
			"--add-modules=ALL-SYSTEM",
			"--add-opens",
			"java.base/java.util=ALL-UNNAMED",
			"--add-opens",
			"java.base/java.lang=ALL-UNNAMED",
			"-javaagent:" .. lombok_path,
			"-jar",
			vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
			"-configuration",
			config_path,
			"-data",
			workspace_dir,
		},

		root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }),

		settings = {
			java = {
				eclipse = {
					downloadSources = true,
				},
				configuration = {
					updateBuildConfiguration = "interactive",
					-- Android SDK 配置
					runtimes = android_home ~= ""
							and {
								{
									name = "JavaSE-11",
									path = java_home,
								},
								{
									name = "JavaSE-17",
									path = java_home,
								},
							}
						or {
							{
								name = "JavaSE-11",
								path = java_home,
							},
							{
								name = "JavaSE-17",
								path = java_home,
							},
						},
				},
				maven = {
					downloadSources = true,
				},
				implementationsCodeLens = {
					enabled = true,
				},
				referencesCodeLens = {
					enabled = true,
				},
				references = {
					includeDecompiledSources = true,
				},
				format = {
					enabled = true,
					settings = {
						-- Google Java Style
						url = "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
						profile = "GoogleStyle",
					},
				},
				signatureHelp = { enabled = true },
				contentProvider = { preferred = "fernflower" },
				completion = {
					favoriteStaticMembers = {
						"org.hamcrest.MatcherAssert.assertThat",
						"org.hamcrest.Matchers.*",
						"org.hamcrest.CoreMatchers.*",
						"org.junit.jupiter.api.Assertions.*",
						"java.util.Objects.requireNonNull",
						"java.util.Objects.requireNonNullElse",
						"org.mockito.Mockito.*",
					},
					filteredTypes = {
						"com.sun.*",
						"io.micrometer.shaded.*",
						"java.awt.*",
						"jdk.*",
						"sun.*",
					},
				},
				sources = {
					organizeImports = {
						starThreshold = 9999,
						staticStarThreshold = 9999,
					},
				},
				codeGeneration = {
					toString = {
						template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
					},
					useBlocks = true,
				},
			},
		},

		-- 初始化选项
		init_options = {
			bundles = bundles,
			extendedClientCapabilities = jdtls.extendedClientCapabilities,
		},

		-- 文件类型
		filetypes = { "java", "kotlin" },
	}

	-- 启动或附加到 LSP
	jdtls.start_or_attach(config)

	-- Java keymaps 已迁移到 keymaps/all.lua (filetype: java/kotlin)
end

-- 自动启动 JDTLS
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "java", "kotlin" },
	callback = function()
		M.setup()
	end,
})

return M
