-- Git Worktree 配置
local worktree = require("git-worktree")

worktree.setup({
	change_directory_command = "cd", -- 切换目录命令
	update_on_change = true, -- 切换 worktree 时自动更新
	update_on_change_command = "e .", -- 更新命令
	clearjumps_on_change = true, -- 切换时清除跳转列表
	autopush = false, -- 不自动推送
})

-- Telescope 集成
local telescope = require("telescope")
telescope.load_extension("git_worktree")

return worktree
