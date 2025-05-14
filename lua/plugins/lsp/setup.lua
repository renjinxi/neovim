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
	automatic_enable = true,
})

local function get_capabilities()
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	capabilities.textDocument.completion.completionItem.snippetSupport = true
	capabilities.textDocument.foldingRange = {
		dynamicRegistration = false,
		lineFoldingOnly = true,
	}

	local status_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
	if not status_ok then
		return capabilities
	end
	return cmp_nvim_lsp.default_capabilities(capabilities)
end

local on_attach = function(client, bufnr) end
local capabilities = get_capabilities()
local handlers = {
	["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
		width = 60,
	}),
	["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { width = 60 }),
	["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
		-- Disable virtual_text
		virtual_text = false,
	}),
}
local lspconfig = require("lspconfig")

local servers = {
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
}

for _, server in ipairs(servers) do
	lspconfig[server].setup({
		on_attach = on_attach,
		capabilities = capabilities,
		handlers = handlers,
	})
end

-- 针对特殊 server 的自定义配置
lspconfig.lua_ls.setup({
	capabilities = capabilities,
	handlers = handlers,
	on_attach = on_attach,
	settings = require("plugins.lsp.servers.lua_ls").settings,
})
lspconfig.pyright.setup({
	capabilities = capabilities,
	handlers = handlers,
	on_attach = on_attach,
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
lspconfig.ruff.setup({
	capabilities = capabilities,
	handlers = handlers,
	on_attach = on_attach,
})
lspconfig.ts_ls.setup({
	capabilities = capabilities,
	handlers = handlers,
	on_attach = on_attach,
})
