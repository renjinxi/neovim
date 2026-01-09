-- ================================
-- Mason 2025年现代化配置
-- 支持 Neovim 0.11+ 和新的 vim.lsp.config API
-- ================================

local M = {}

function M.setup()
	-- Mason 基础配置
	require("mason").setup({
		ui = {
			border = "rounded",
			icons = {
				package_installed = "✓",
				package_pending = "➜",
				package_uninstalled = "✗",
			},
		},
		max_concurrent_installers = 4,
		-- 打开Mason时检查过期包
		check_outdated_packages_on_open = true,
		-- 启用日志记录
		log_level = vim.log.levels.INFO,
	})

	-- Mason-lspconfig 配置 (2025年最新版本)
	require("mason-lspconfig").setup({
		-- 确保安装这些LSP服务器
		ensure_installed = {
			-- Web 开发
			"ts_ls", -- TypeScript (2025年重命名，原 tsserver)
			"html",
			"cssls",
			"jsonls",
			"eslint",
			"vue_ls", -- Vue Language Server
			"emmet_language_server", -- Emmet 支持

			-- 系统编程
			"clangd", -- C/C++
			"rust_analyzer",
			"gopls", -- Go

			-- 脚本语言
			"lua_ls", -- Lua
			"pyright", -- Python
			"ruff", -- Python linting/formatting (2025年新增)
			"bashls", -- Bash

			-- Java/Kotlin/Android 开发
			"jdtls", -- Java Language Server
			"kotlin_language_server", -- Kotlin

			-- 配置文件
			"yamlls",
			"nginx_language_server",

			-- 标记语言
			"marksman", -- Markdown
		},

		-- 2025年新特性：自动启用已安装的服务器
		automatic_enable = true,

		-- 可以排除某些服务器不自动启用
		-- automatic_enable = {
		--     exclude = { "rust_analyzer" }
		-- },

		-- 或者只启用特定服务器
		-- automatic_enable = { "lua_ls", "pyright" }
	})

	-- 创建有用的用户命令（移除自动更新功能）
	M.setup_commands()
end

-- 创建用户命令
function M.setup_commands()
	-- 只更新注册表
	vim.api.nvim_create_user_command("MasonUpdateRegistry", function()
		vim.cmd("MasonUpdate")
		vim.notify("📋 Mason 注册表已更新", vim.log.levels.INFO)
	end, {
		desc = "更新 Mason 注册表（包信息）",
	})

	-- 重新安装所有包（强制更新）
	vim.api.nvim_create_user_command("MasonReinstallAll", function()
		local mason_registry = require("mason-registry")
		local installed_packages = mason_registry.get_installed_package_names()

		if #installed_packages > 0 then
			local choice = vim.fn.confirm(
				string.format(
					"确定要重新安装所有 %d 个包吗？\n这会将它们更新到最新版本\n\n包列表: %s",
					#installed_packages,
					table.concat(installed_packages, ", ")
				),
				"&Yes\n&No",
				2
			)

			if choice == 1 then
				-- 先更新注册表
				vim.cmd("MasonUpdate")
				-- 延迟后重新安装所有包
				vim.defer_fn(function()
					local install_cmd = "MasonInstall " .. table.concat(installed_packages, " ")
					vim.cmd(install_cmd)
					vim.notify("🔄 正在重新安装所有包...", vim.log.levels.INFO)
				end, 2000)
			end
		else
			vim.notify("📦 没有已安装的包", vim.log.levels.WARN)
		end
	end, {
		desc = "重新安装所有已安装的包（强制更新到最新版本）",
	})

	-- 安装缺失的包
	vim.api.nvim_create_user_command("MasonInstallMissing", function()
		local mason_lspconfig = require("mason-lspconfig")
		mason_lspconfig.setup({}) -- 重新检查 ensure_installed
		vim.notify("🔧 正在安装缺失的 LSP 服务器...", vim.log.levels.INFO)
	end, {
		desc = "安装配置中缺失的 LSP 服务器",
	})

	-- 显示已安装包的状态
	vim.api.nvim_create_user_command("MasonStatus", function()
		local mason_registry = require("mason-registry")
		local installed = mason_registry.get_installed_package_names()
		local count = #installed
		vim.notify(
			string.format("📦 已安装 %d 个包:\n%s", count, table.concat(installed, ", ")),
			vim.log.levels.INFO,
			{ title = "Mason 状态" }
		)
	end, {
		desc = "显示 Mason 包状态",
	})
end

return M

