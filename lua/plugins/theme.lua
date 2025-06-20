local M = {}

-- 可选的自定义高亮组配置
local highlights = {
	-- 如果需要自定义某些高亮组，可以在这里添加
	-- VertSplit = { bg = "NONE", fg = "#005f87" },
}

-- 应用高亮组配置
local function apply_highlights()
	for group_name, group_settings in pairs(highlights) do
		vim.api.nvim_set_hl(0, group_name, group_settings)
	end
end

function M.setup()
	-- 如果有自定义高亮，创建自动命令组
	if next(highlights) then
		local theme_group = vim.api.nvim_create_augroup("ThemeCustomization", { clear = true })
		
		vim.api.nvim_create_autocmd("ColorScheme", {
			group = theme_group,
			callback = function()
				apply_highlights()
			end,
		})
		
		-- 应用自定义高亮
		apply_highlights()
	end
end

return M
