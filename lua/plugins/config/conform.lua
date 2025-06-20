-- ================================
-- Conform 代码格式化配置 (2025年现代化配置)
-- ================================

local opts = {
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "isort", "black" },
		javascript = { { "prettierd", "prettier" } },
		typescript = { { "prettierd", "prettier" } },
		javascriptreact = { { "prettierd", "prettier" } },
		typescriptreact = { { "prettierd", "prettier" } },
		vue = { { "prettierd", "prettier" } },
		css = { { "prettierd", "prettier" } },
		scss = { { "prettierd", "prettier" } },
		html = { { "prettierd", "prettier" } },
		json = { { "prettierd", "prettier" } },
		jsonc = { { "prettierd", "prettier" } },
		yaml = { { "prettierd", "prettier" } },
		markdown = { { "prettierd", "prettier" } },
		go = { "goimports", "gofmt" },
		rust = { "rustfmt" },
		c = { "clang-format" },
		cpp = { "clang-format" },
	},
	default_format_opts = {
		lsp_format = "fallback",
	},
	format_on_save = {
		timeout_ms = 500,
		lsp_fallback = true,
	},
}

require("conform").setup(opts)

-- 设置格式化表达式
vim.o.formatexpr = "v:lua.require'conform'.formatexpr()" 