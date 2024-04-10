require("coverage").setup({
	commands = true, -- create commands
	highlights = {
		-- customize highlight groups created by the plugin
		covered = { fg = "#C3E88D" },   -- supports style, fg, bg, sp (see :h highlight-gui)
		uncovered = { fg = "#F07178" },
	},
	signs = {
		-- use your own highlight groups or text markers
		covered = { hl = "CoverageCovered", text = "▎" },
		uncovered = { hl = "CoverageUncovered", text = "▎" },
	},
	summary = {
		-- customize the summary pop-up
		min_coverage = 80.0,      -- minimum coverage threshold (used for highlighting)
	},
	lang = {
		-- customize language specific settings
	},
})
--require("coverage").setup({
    --commands = true, -- create commands
    --highlights = {
        ---- customize highlight groups created by the plugin
        ----covered = { fg = "#A6E22E" }, -- 使用淡橄榄绿表示已覆盖代码
        --covered = { fg = "#afd700" },
        ----uncovered = { fg = "#FD971F" }, -- 使用明亮的橙色表示未覆盖代码
        --uncovered = { fg = "#dfaf8f" },
    --},
    --signs = {
        ---- use your own highlight groups or text markers
        --covered = { hl = "CoverageCovered", text = "▎" },
        --uncovered = { hl = "CoverageUncovered", text = "▎" },
    --},
    --summary = {
        ---- customize the summary pop-up
        --min_coverage = 80.0, -- minimum coverage threshold (used for highlighting)
    --},
    --lang = {
        ---- customize language specific settings
    --},
--})
