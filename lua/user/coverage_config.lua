local coverage = require("coverage")

local show_coverage = false

local function toggle_coverage(ev)
    show_coverage = not show_coverage
    coverage.load(show_coverage)
end

local function load_cb()
    if show_coverage then
        coverage.show()
    else
        coverage.hide()
    end
end

-- Setup coverage
coverage.setup({
    auto_reload = true,
    load_coverage_cb = load_cb,
    commands = true, -- create commands
    highlights = {
        -- customize highlight groups created by the plugin
        covered = { fg = "#9fbed9" }, -- supports style, fg, bg, sp (see :h highlight-gui)
        uncovered = { fg = "#d86306" },
    },
    signs = {
        -- use your own highlight groups or text markers
        covered = { hl = "CoverageCovered", text = "▎" },
        uncovered = { hl = "CoverageUncovered", text = "▎" },
    },
    summary = {
        -- customize the summary pop-up
        min_coverage = 80.0, -- minimum coverage threshold (used for highlighting)
    },
    lang = {
        -- customize language specific settings
    },
})

-- Auto-load for python
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'python',
    desc = 'Auto-load coverage in python projects',
    callback = coverage.load,
})
