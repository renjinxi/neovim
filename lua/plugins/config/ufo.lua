-- Ufo 折叠配置
-- Keymaps 已迁移到 keymaps/all.lua

require("ufo").setup({
	provider_selector = function(bufnr, filetype, buftype)
		return { "lsp", "indent" }
	end,
})
