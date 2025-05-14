local M = {}

function M.setup()
	local keymap = {
		{ "<leader>s", group = "Lazygit", nowait = false, remap = false },
		{ "<leader>sl", ":LazyGit<cr>", desc = "Lazygit", nowait = false, remap = false },
		{ "<leader>sa", ":Git add %<cr>", desc = "Add Current File", nowait = false, remap = false },
		{ "<leader>sA", ":Git add .<cr>", desc = "Add All File", nowait = false, remap = false },
		{ "<leader>sm", ":Git commit<cr>", desc = "Commit", nowait = false, remap = false },
		{ "<leader>sd", ":Git diff %<cr>", desc = "Diff Current File", nowait = false, remap = false },
		{ "<leader>si", ":Git diff .<cr>", desc = "Diff All File", nowait = false, remap = false },
		{ "<leader>sD", ":Git diff --cached %<cr>", desc = "Diff Current File Cached", nowait = false, remap = false },
		{ "<leader>so", ":Git log<cr>", desc = "Log", nowait = false, remap = false },
		{ "<leader>sI", ":Git diff --cached .<cr>", desc = "Diff All File Cached", nowait = false, remap = false },
		{
			"<leader>sp",
			":Git pull origin main --rebase<cr>",
			desc = "Pull Origin Main",
			nowait = false,
			remap = false,
		},
		{
			"<leader>sP",
			":Git push origin main <cr>",
			desc = "Push Origin Main",
			nowait = false,
			remap = false,
		},
		{ "<leader>sn", function() require('gitsigns').next_hunk() end, desc = "下一个变更块", nowait = false, remap = false },
		{ "<leader>sp", function() require('gitsigns').prev_hunk() end, desc = "上一个变更块", nowait = false, remap = false },
		{ "<leader>ss", function() require('gitsigns').stage_hunk() end, desc = "暂存变更块", nowait = false, remap = false },
		{ "<leader>sr", function() require('gitsigns').reset_hunk() end, desc = "撤销变更块", nowait = false, remap = false },
		{ "<leader>su", function() require('gitsigns').undo_stage_hunk() end, desc = "撤销暂存变更块", nowait = false, remap = false },
		{ "<leader>sh", function() require('gitsigns').preview_hunk() end, desc = "预览变更块", nowait = false, remap = false },
		{ "<leader>sb", function() require('gitsigns').blame_line{full=true} end, desc = "当前行 blame", nowait = false, remap = false },
		{ "<leader>sd", function() require('gitsigns').diffthis() end, desc = "当前文件 diff", nowait = false, remap = false },
		{ "<leader>sD", function() require('gitsigns').diffthis('~') end, desc = "与上次提交 diff", nowait = false, remap = false },
		{ "<leader>st", function() require('gitsigns').toggle_current_line_blame() end, desc = "切换行 blame", nowait = false, remap = false },
		{ "<leader>sT", function() require('gitsigns').toggle_deleted() end, desc = "切换显示已删除行", nowait = false, remap = false },
	}
	require("which-key").add(keymap)
end

return M
