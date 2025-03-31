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
	}
	require("which-key").add(keymap)
end

return M
