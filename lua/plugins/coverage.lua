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
		window = {},
	},
	lang = {
		-- customize language specific settings
	},
})

local which_key = require("which-key")
local coverage_keymap = {
	{ "<leader>e", group = "Coverage", nowait = false, remap = false },
	{ "<leader>eh", ":CoverageHid<cr>", desc = "Hide", nowait = false, remap = false },
	{ "<leader>el", ":CoverageLoad<cr>", desc = "Load", nowait = false, remap = false },
	{ "<leader>eo", ":CoverageShow<cr>", desc = "Show", nowait = false, remap = false },
	{ "<leader>es", ":CoverageSummary<cr><cr>", desc = "Summary", nowait = false, remap = false },
}
which_key.add(coverage_keymap)
