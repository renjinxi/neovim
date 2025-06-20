-- ================================
-- VimTeX LaTeX支持配置
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

-- 取消默认快捷键
vim.g.vimtex_mappings_enabled = 0

-- 自定义 <leader>t 开头快捷键
vim.api.nvim_create_autocmd("FileType", {
	pattern = "tex",
	callback = function()
		local opts = { buffer = true, noremap = true, silent = true, desc = "Vimtex" }
		vim.keymap.set("n", "<leader>tc", "<Plug>(vimtex-clean)", opts)
		vim.keymap.set("n", "<leader>tl", "<Plug>(vimtex-compile)", opts)
		vim.keymap.set("n", "<leader>tv", "<Plug>(vimtex-view)", opts)
		vim.keymap.set("n", "<leader>te", "<Plug>(vimtex-errors)", vim.tbl_extend("force", opts, { desc = "LaTeX 查看错误" }))
		vim.keymap.set("n", "<leader>ts", "<Plug>(vimtex-status)", vim.tbl_extend("force", opts, { desc = "LaTeX 编译状态" }))
		vim.keymap.set("n", "<leader>tk", "<Plug>(vimtex-stop)", vim.tbl_extend("force", opts, { desc = "LaTeX 停止编译" }))
		vim.keymap.set("n", "<leader>tt", "<Plug>(vimtex-compile-output)", vim.tbl_extend("force", opts, { desc = "LaTeX 编译输出" }))
		vim.keymap.set("n", "<leader>tf", "<Plug>(vimtex-reload)", vim.tbl_extend("force", opts, { desc = "LaTeX 重新加载" }))
		vim.keymap.set("n", "<leader>tj", "<Plug>(vimtex-next-error)", vim.tbl_extend("force", opts, { desc = "LaTeX 下一个错误" }))
		vim.keymap.set("n", "<leader>th", "<Plug>(vimtex-prev-error)", vim.tbl_extend("force", opts, { desc = "LaTeX 上一个错误" }))
		vim.keymap.set("n", "<leader>tp", "<Plug>(vimtex-toggle-main)", vim.tbl_extend("force", opts, { desc = "LaTeX 切换主文件" }))
	end,
}) 