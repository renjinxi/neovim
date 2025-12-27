-- ================================
-- VimTeX LaTeX支持配置
-- Keymaps 已迁移到 keymaps/all.lua (filetype: tex)
-- ================================

-- 基本设置
vim.g.vimtex_view_method = "skim"
vim.g.vimtex_compiler_method = "latexmk"
vim.g.vimtex_quickfix_mode = 0
vim.g.vimtex_view_skim_sync = 1
vim.g.vimtex_view_skim_activate = 1
vim.g.vimtex_compiler_latexmk_engines = {
	_ = "-xelatex",
}

-- 中文支持：用 xelatex 编译
vim.g.vimtex_compiler_latexmk = {
	build_dir = '',
	callback = 1,
	continuous = 1,
	executable = "latexmk",
	options = {
		"-file-line-error",
		"-synctex=1",
		"-interaction=nonstopmode",
	},
}

-- 取消默认快捷键 (使用 keymaps/all.lua 中的定义)
vim.g.vimtex_mappings_enabled = 0 