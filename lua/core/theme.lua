local M = {}

-- 主题特定的高亮组配置
local highlights = {
    VertSplit = { bg = "NONE", fg = "#005f87" },
    -- 在这里可以添加更多高亮组配置
}

-- 应用高亮组配置
local function apply_highlights()
    for group_name, group_settings in pairs(highlights) do
        vim.api.nvim_set_hl(0, group_name, group_settings)
    end
end

-- 主题设置
local function setup_colorscheme()
    -- 设置主题
    local colorscheme = "rose-pine"
    local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
    if not status_ok then
        vim.notify("colorscheme " .. colorscheme .. " not found!", vim.log.levels.ERROR)
        return
    end
    
    -- 应用自定义高亮
    apply_highlights()
end

function M.setup()
    -- 创建自动命令组
    local theme_group = vim.api.nvim_create_augroup("ThemeCustomization", { clear = true })
    
    -- 确保主题设置在颜色方案改变时重新应用
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = theme_group,
        callback = function()
            apply_highlights()
        end,
    })
    
    -- 初始化主题设置
    setup_colorscheme()
end

return M
