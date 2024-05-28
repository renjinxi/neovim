local window = function()
    return vim.api.nvim_win_get_number(0)
end

local cond200 = function()
    return vim.fn.winwidth(0) > 200
end
local cond80 = function()
    return vim.fn.winwidth(0) > 80
end
local cond40 = function()
    return vim.fn.winwidth(0) > 40
end

local codeium_state = function()
    return vim.api.nvim_call_function("codeium#GetStatusString", {})
end

local function clock()
    return os.date('%Y-%m-%d %H:%M') -- Formats time in HH:MM:SS format
end

local function get_project_root()
    local cwd = vim.loop.cwd()
    while true do
        if vim.loop.fs_stat(cwd .. '/.git') then
            return cwd:match("([^/\\]+)$") -- returns the name of the current directory
        end
        local parent = cwd:match("(.*)[/\\]")
        if not parent or parent == cwd then break end
        cwd = parent
    end
    return '[No Project]' -- default name if no .git directory is found
end

require("lualine").setup({
    options = {
        theme = "Tomorrow",
        --theme = "PaperColor",
        --theme = "papercolor_dark",
        --component_separators = { left = '', right = '' },
        --section_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
        component_separators = { left = '', right = '' },
        --section_separators = "",
        --component_separators = "",
        --theme = "papercolor_dark",
    },
    sections = {
        lualine_a = {
            window, { "mode", cond = cond80 },
        },
        lualine_b = {
            { "branch",      cond = cond200 },
            { "diff",        cond = cond200 },
            { "diagnostics", cond = cond200, },
        },
        lualine_c = {
            { "filename", cond = cond40 },

        },
        lualine_x = {
            { "copilot", },
            --{ codeium_state,  },
            { "encoding",   cond = cond80 },
            { "fileformat", cond = cond200 },
            { "filetype",   cond = cond200 },

        },
        lualine_y = {
            { "progress", cond = cond80 },
            { "location", cond = cond200 },
        },
        lualine_z = {
            {
                clock,
                cond = cond40,
            }

        },
    },
    inactive_sections = {
        lualine_a = { window, { "filename", cond = cond40 } }
    },
    tabline = {
        -- lualine_a = {'buffers'},
        lualine_a = {
            {
                "tabs",
                mode = 2
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
