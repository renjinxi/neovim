local status_ok, _ = pcall(require, "lspconfig")

if not status_ok then
	return
end

-- 先加载 LSP server 配置
require("plugins.lsp.setup")

-- 然后应用 diagnostic 配置，确保不被覆盖
require("plugins.lsp.config")

-- 在 LSP attach 时再次确保 sign 配置生效
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function()
		-- 确保 sign 配置在 LSP attach 后生效
		vim.schedule(function()
			require("plugins.lsp.config")
		end)
	end,
})
