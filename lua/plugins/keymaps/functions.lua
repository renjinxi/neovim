-- ============================================================================
-- Keymap 回调函数集合
-- 所有复杂的回调函数集中在此，供 all.lua 引用
-- ============================================================================
local M = {}
local terminal = require("core.terminal")
local editor = require("plugins.keymaps.modules.editor")
local dev = require("plugins.keymaps.modules.dev")
local git = require("plugins.keymaps.modules.git").setup({ terminal = terminal })
local terminal_runtime = require("plugins.keymaps.modules.terminal_runtime").setup({ terminal = terminal })
local float_runtime = require("plugins.keymaps.modules.float_runtime").setup({ terminal = terminal })

-- 已拆分到领域模块的通用能力。
-- 仍保留在本文件中的主要是 AI/终端编排和多窗口状态管理。
M = vim.tbl_extend("force", M, editor, dev, git, terminal_runtime.api)

-- ============================================================================
-- Editor: Terminal（原生 API 实现）
-- ============================================================================
local create_float_term = terminal_runtime.create_float_term
local create_horizontal_term = terminal_runtime.create_horizontal_term
local create_vertical_term = terminal_runtime.create_vertical_term
local create_tab_term = terminal_runtime.create_tab_term
local toggle_term = terminal_runtime.toggle_term
local create_float_terminal = float_runtime.create_float_terminal
local reopen_float_window = float_runtime.reopen_float_window
local float_terminals = float_runtime.float_terminals

local misc = require("plugins.keymaps.modules.misc").setup({
	float_terminals = float_terminals,
	create_float_terminal = create_float_terminal,
	reopen_float_window = reopen_float_window,
})
local ai_mod = require("plugins.keymaps.modules.ai").setup({
	toggle_term = toggle_term,
	create_tab_term = create_tab_term,
	create_float_term = create_float_term,
	create_horizontal_term = create_horizontal_term,
	create_vertical_term = create_vertical_term,
	create_float_terminal = create_float_terminal,
	reopen_float_window = reopen_float_window,
	float_terminals = float_terminals,
})
local ai = ai_mod.api
float_runtime.api.set_ai_state({
	ai_float_profiles = ai_mod.ai_float_profiles,
	build_ai_command = ai_mod.build_ai_command,
	build_ai_label = ai_mod.build_ai_label,
})
M = vim.tbl_extend("force", M, misc)
M = vim.tbl_extend("force", M, ai)
M = vim.tbl_extend("force", M, float_runtime.api)
M.ai_completions = ai.ai_completions


return M
