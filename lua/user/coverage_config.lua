local coverage = require("coverage")

local show_coverage = false

local function toggle_coverage()
    show_coverage = not show_coverage
    coverage.load(show_coverage)
end

local function show_summary()
    if not show_coverage then
        toggle_coverage()
    end
    coverage.summary()
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
        window = {

        }
    },
    lang = {
        -- customize language specific settings
    },
})

-- Auto-load for python
--vim.api.nvim_create_autocmd('FileType', {
--pattern = 'python',
--desc = 'Auto-load coverage in python projects',
--callback = coverage.load,
--})


local which_key = require("which-key")
local n_opts = {
    mode = "n",
    prefix = "<leader>",
    buffer = nil,
    silent = true,
    noremap = true,
    nowait = false,
}

local coverage_keymap = {
    e = {
        name = "Coverage",
        l = { ":CoverageLoad<cr>", "Load" },
        h = { ":CoverageHid<cr>", "Hide" },
        o = { ":CoverageShow<cr>", "Show" },
        s = { ":CoverageSummary<cr><cr>", "Summary"},
    }

}

which_key.register(coverage_keymap, n_opts)
