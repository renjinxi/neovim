local status_ok, lualine = pcall(require, "lualine")
if not status_ok then
        return
end

local window = function()
        return vim.api.nvim_win_get_number(0)
end

lualine.setup({
        options = {
                --theme = "nightfly"
                --theme = "Tomorrow"
                --theme = "papercolor_light"
                --theme = "ayu_light"
                --theme = "iceberg_light"
                --theme = "onelight"
                -- theme = "gruvbox_dark"
                --theme = "material"
                --theme = "solarized_light"
                --theme = "gruvbox_light"
                theme = "solarized_light",
                --theme = "onelight"
                --theme = "github"

                -- icons_enabled = true,
                -- theme = 'auto',
                -- component_separators = { left = '', right = ''},
                -- section_separators = { left = '', right = ''},
                --disabled_filetypes = {},
                disabled_filetypes = {
                        --statusline = {},
                        --statusline = { "NvimTree" },
                        --winbar = { "NvimTree" },
                },
                -- always_divide_middle = true,
        },
        sections = {
                lualine_a = { window, "mode" },
                lualine_b = { "branch", "diff", "diagnostics" },
                lualine_c = { "filename" },
                lualine_x = { "encoding", "fileformat", "filetype" },
                lualine_y = { "progress" },
                lualine_z = { "location" },
        },
        inactive_sections = {
                --lualine_a = {'mode' },
                --lualine_a = { window, "mode"},
                lualine_a = { window, "filename" },
                --lualine_b = { "branch", "diff", "diagnostics" },
                --lualine_c = { "filename" },
                --lualine_x = { "encoding", "fileformat", "filetype" },
                --lualine_y = { "progress" },
                --lualine_z = { "location" },
        },
        --inactive_sections = {
        --lualine_a = {},
        --lualine_b = {},
        --lualine_c = {'filename'},
        --lualine_x = {'location'},
        --lualine_y = {},
        --lualine_z = {}
        --},
        -- tabline = {},
        tabline = {
                -- lualine_a = {'buffers'},
                lualine_a = {
                        {
                                "tabs",
                                mode = 2,
                        },
                },
                -- lualine_b = {'branch'},
                lualine_b = {},
                lualine_c = { "filename" },
                lualine_x = {},
                lualine_y = {},
                lualine_z = { "tabs" },
        },
        extensions = {},
})
