local mason_ok, _ = pcall(require, "mason")
local mason_lsp_ok, mason_lsp = pcall(require, "mason-lspconfig")

if not mason_ok or not mason_lsp_ok then
	return
end

mason_lsp.setup({
	ensure_installed = {
		"lua_ls",
		"clangd",
		"pyright",
		"ruff",
		"html",
		"cssls",
		"ts_ls",
		"gopls",
		"golangci_lint_ls",
		"nginx_language_server",
	},
	automatic_installation = true,
})

-- 获取 capabilities（简化版本）
local function get_capabilities()
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	
	local status_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
	if status_ok then
		capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
	end
	
	return capabilities
end

-- 通用 on_attach 函数
local function on_attach(client, bufnr)
	-- 在这里可以添加 LSP 相关的键位绑定
	-- 例如：vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr })
end

-- 简化的 handlers（移除已废弃的 publishDiagnostics）
local handlers = {
	["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
		border = "rounded",
		width = 60,
	}),
	["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
		border = "rounded",
		width = 60,
	}),
}

local capabilities = get_capabilities()
local lspconfig = require("lspconfig")

-- 通用配置函数
local function setup_server(server_name, opts)
	local default_opts = {
		on_attach = on_attach,
		capabilities = capabilities,
		handlers = handlers,
	}
	
	if opts then
		default_opts = vim.tbl_deep_extend("force", default_opts, opts)
	end
	
	lspconfig[server_name].setup(default_opts)
end

-- 配置各个 LSP server
local servers = {
	"clangd",
	"ruff", 
	"html",
	"cssls",
	"ts_ls",
	"gopls",
	"golangci_lint_ls",
	"nginx_language_server",
}

-- 配置通用 server
for _, server in ipairs(servers) do
	setup_server(server)
end

-- 配置需要特殊设置的 server
setup_server("lua_ls", {
	settings = require("plugins.lsp.servers.lua_ls").settings,
})

setup_server("pyright", {
	settings = {
		python = {
			analysis = {
				diagnosticSeverityOverrides = {
					reportUnusedVariable = "none",
					reportUnusedImport = "none",
				},
			},
		},
	},
})
