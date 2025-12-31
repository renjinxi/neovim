-- ================================
-- Diffview Git差异查看配置
-- ================================

require("diffview").setup({
	enhanced_diff_hl = true,
	view = {
		default = {
			-- Config for changed files, and staged files in diff views.
			layout = "diff2_vertical",
			disable_diagnostics = false, -- Temporarily disable diagnostics for diff buffers while in the view.
			winbar_info = false, -- See |diffview-config-view.x.winbar_info|
		},
		merge_tool = {
			layout = "diff3_mixed",
		},
	},
	hooks = {
		-- 解决冲突后自动保存（因为 auto-save 插件不会被 API 修改触发）
		diff_buf_read = function(bufnr)
			-- 监听 buffer 变化，延迟保存
			vim.api.nvim_create_autocmd("TextChanged", {
				buffer = bufnr,
				callback = function()
					if vim.bo[bufnr].modified and vim.bo[bufnr].modifiable then
						vim.defer_fn(function()
							if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].modified then
								vim.api.nvim_buf_call(bufnr, function()
									vim.cmd("silent! write")
								end)
							end
						end, 200)
					end
				end,
			})
		end,
	},
}) 