local M = {}

-- ============================================================================
-- macOS Option 键特殊字符映射表
-- ============================================================================
-- 在 macOS 上，Option+键会产生特殊的 Unicode 字符，我们直接映射这些字符
-- 这样可以在所有模式下（Normal, Insert, Visual, Terminal）都能使用

local option_mappings = {
	-- Option + 数字键 (用于窗口导航)
	numbers = {
		["¡"] = { key = "Option+1", window = 1 },  -- Option+1
		["™"] = { key = "Option+2", window = 2 },  -- Option+2
		["£"] = { key = "Option+3", window = 3 },  -- Option+3
		["¢"] = { key = "Option+4", window = 4 },  -- Option+4
		["∞"] = { key = "Option+5", window = 5 },  -- Option+5
		["§"] = { key = "Option+6", window = 6 },  -- Option+6
		["¶"] = { key = "Option+7", window = 7 },  -- Option+7
		["•"] = { key = "Option+8", window = 8 },  -- Option+8
		["ª"] = { key = "Option+9", window = 9 },  -- Option+9
	},

	-- Option + 字母键 (预留给其他功能)
	letters = {
		["å"] = { key = "Option+a" },  -- Option+a - 可用于其他功能
		["∫"] = { key = "Option+b" },  -- Option+b
		["ç"] = { key = "Option+c" },  -- Option+c
		["∂"] = { key = "Option+d" },  -- Option+d
		["´"] = { key = "Option+e" },  -- Option+e
		["ƒ"] = { key = "Option+f" },  -- Option+f
		["©"] = { key = "Option+g" },  -- Option+g
		["˙"] = { key = "Option+h" },  -- Option+h
		["ˆ"] = { key = "Option+i" },  -- Option+i
		["∆"] = { key = "Option+j" },  -- Option+j
		["˚"] = { key = "Option+k" },  -- Option+k
		["¬"] = { key = "Option+l" },  -- Option+l
		["µ"] = { key = "Option+m" },  -- Option+m
		["˜"] = { key = "Option+n" },  -- Option+n
		["ø"] = { key = "Option+o" },  -- Option+o
		["π"] = { key = "Option+p" },  -- Option+p
		["œ"] = { key = "Option+q" },  -- Option+q
		["®"] = { key = "Option+r" },  -- Option+r
		["ß"] = { key = "Option+s" },  -- Option+s
		["†"] = { key = "Option+t" },  -- Option+t
		["¨"] = { key = "Option+u" },  -- Option+u
		["√"] = { key = "Option+v" },  -- Option+v
		["∑"] = { key = "Option+w" },  -- Option+w
		["≈"] = { key = "Option+x" },  -- Option+x
		["¥"] = { key = "Option+y" },  -- Option+y
		["Ω"] = { key = "Option+z" },  -- Option+z
	}
}

function M.setup()
	local opts = { noremap = true, silent = true }
	local term_opts = { silent = true }

	-- ============================================================================
	-- 标签页导航映射
	-- ============================================================================

	-- gt 和 gT 在 insert 模式下切换标签页并返回 normal 模式
	vim.keymap.set("i", "gt", "<Esc>gt", opts)
	vim.keymap.set("i", "gT", "<Esc>gT", opts)

	-- Ctrl+数字 在所有模式下切换到对应标签页
	for i = 1, 9 do
		-- Normal 模式
		vim.keymap.set("n", "<C-" .. i .. ">", i .. "gt", opts)
		-- Insert 模式 - 切换后返回 normal 模式
		vim.keymap.set("i", "<C-" .. i .. ">", "<Esc>" .. i .. "gt", opts)
		-- Visual 模式
		vim.keymap.set("v", "<C-" .. i .. ">", "<Esc>" .. i .. "gt", opts)
		-- Terminal 模式下的标签页切换
		vim.keymap.set("t", "<C-" .. i .. ">", [[<C-\><C-n>]] .. i .. [[gt]], term_opts)
	end

	-- 在终端模式下的 gt/gT 映射
	vim.keymap.set("t", "gt", [[<C-\><C-n>gt]], term_opts)
	vim.keymap.set("t", "gT", [[<C-\><C-n>gT]], term_opts)

	-- ============================================================================
	-- 窗口导航映射 (Option+数字键通过特殊字符)
	-- ============================================================================

	-- 设置窗口切换映射
	for char, mapping in pairs(option_mappings.numbers) do
		local window_num = mapping.window
		local cmd = string.format("<cmd>%dwincmd w<cr>", window_num)
		local desc = string.format("Switch to window %d (%s)", window_num, mapping.key)

		-- Normal 模式
		vim.keymap.set("n", char, cmd, {
			desc = desc,
			noremap = true,
			silent = true
		})

		-- Insert 模式 - 切换窗口并保持在 normal 模式
		vim.keymap.set("i", char, "<Esc>" .. cmd, {
			desc = desc,
			noremap = true,
			silent = true
		})

		-- Visual 模式 - 退出 visual 模式并切换窗口
		vim.keymap.set("v", char, "<Esc>" .. cmd, {
			desc = desc,
			noremap = true,
			silent = true
		})

		-- Terminal 模式 - 退出终端模式并切换窗口
		vim.keymap.set("t", char, [[<C-\><C-n>]] .. cmd, {
			desc = desc,
			silent = true
		})
	end

	-- ============================================================================
	-- 扩展 Option 键功能 (使用字母键的特殊字符)
	-- ============================================================================

	-- Option+s (ß) - 快速保存
	local save_cmd = "<cmd>w<cr>"
	vim.keymap.set("n", "ß", save_cmd, { desc = "Quick save (Option+s)", noremap = true, silent = true })
	vim.keymap.set("i", "ß", "<Esc>" .. save_cmd, { desc = "Quick save (Option+s)", noremap = true, silent = true })

	-- Option+q (œ) - 快速退出当前窗口
	local quit_cmd = "<cmd>q<cr>"
	vim.keymap.set("n", "œ", quit_cmd, { desc = "Quick quit (Option+q)", noremap = true, silent = true })

	-- Option+w (∑) - 关闭当前缓冲区但保持窗口
	local close_buffer_cmd = "<cmd>bdelete<cr>"
	vim.keymap.set("n", "∑", close_buffer_cmd, { desc = "Close buffer (Option+w)", noremap = true, silent = true })

	-- Option+t (†) - Toggle nvim-tree
	local tree_toggle_cmd = "<cmd>NvimTreeToggle<cr>"
	vim.keymap.set("n", "†", tree_toggle_cmd, { desc = "Toggle nvim-tree (Option+t)", noremap = true, silent = true })
	vim.keymap.set("i", "†", "<Esc>" .. tree_toggle_cmd, { desc = "Toggle nvim-tree (Option+t)", noremap = true, silent = true })
	vim.keymap.set("v", "†", "<Esc>" .. tree_toggle_cmd, { desc = "Toggle nvim-tree (Option+t)", noremap = true, silent = true })
	vim.keymap.set("t", "†", [[<C-\><C-n>]] .. tree_toggle_cmd, { desc = "Toggle nvim-tree (Option+t)", silent = true })

	-- Option+g (©) - Toggle Overseer
	local overseer_toggle_cmd = "<cmd>OverseerToggle<cr>"
	vim.keymap.set("n", "©", overseer_toggle_cmd, { desc = "Toggle Overseer (Option+g)", noremap = true, silent = true })
	vim.keymap.set("i", "©", "<Esc>" .. overseer_toggle_cmd, { desc = "Toggle Overseer (Option+g)", noremap = true, silent = true })
	vim.keymap.set("v", "©", "<Esc>" .. overseer_toggle_cmd, { desc = "Toggle Overseer (Option+g)", noremap = true, silent = true })
	vim.keymap.set("t", "©", [[<C-\><C-n>]] .. overseer_toggle_cmd, { desc = "Toggle Overseer (Option+g)", silent = true })

	-- Option+l (¬) - Overseer Restart Last Task
	local overseer_restart_cmd = "<cmd>OverseerRestartLast<cr>"
	vim.keymap.set("n", "¬", overseer_restart_cmd, { desc = "Overseer Restart Last (Option+l)", noremap = true, silent = true })
	vim.keymap.set("i", "¬", "<Esc>" .. overseer_restart_cmd, { desc = "Overseer Restart Last (Option+l)", noremap = true, silent = true })
	vim.keymap.set("v", "¬", "<Esc>" .. overseer_restart_cmd, { desc = "Overseer Restart Last (Option+l)", noremap = true, silent = true })
	vim.keymap.set("t", "¬", [[<C-\><C-n>]] .. overseer_restart_cmd, { desc = "Overseer Restart Last (Option+l)", silent = true })
end

return M