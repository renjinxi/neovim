local M = {}

function M.setup()
	local keymap = {
		-- Git 工具组 (多种选择)
		{ "<leader>s", group = "Git", nowait = false, remap = false },
		
		-- 三种Git界面选择
		{ "<leader>sg", ":Neogit<cr>", desc = "Neogit (现代界面)", nowait = false, remap = false },
		{ "<leader>sl", ":LazyGit<cr>", desc = "LazyGit (终端界面)", nowait = false, remap = false },
		{ "<leader>sf", ":Git<cr>", desc = "Fugitive (命令行)", nowait = false, remap = false },
		
		-- 文件操作 (vim-fugitive 命令)
		{ "<leader>sa", ":Git add %<cr>", desc = "Add Current File", nowait = false, remap = false },
		{ "<leader>sA", ":Git add .<cr>", desc = "Add All Files", nowait = false, remap = false },
		{ "<leader>sm", ":Git commit<cr>", desc = "Commit", nowait = false, remap = false },
		
		-- 查看和对比 (多种选择)
		{ "<leader>sd", ":Git diff %<cr>", desc = "Diff Current File (fugitive)", nowait = false, remap = false },
		{ "<leader>si", ":Git diff .<cr>", desc = "Diff All Files", nowait = false, remap = false },
		{ "<leader>sD", ":Git diff --cached %<cr>", desc = "Diff Staged", nowait = false, remap = false },
		{ "<leader>so", ":Git log<cr>", desc = "Git Log", nowait = false, remap = false },
		
		-- 现代化diff界面 (可选)
		{ "<leader>sv", ":DiffviewOpen<cr>", desc = "DiffView (现代界面)", nowait = false, remap = false },
		{ "<leader>sc", ":DiffviewFileHistory<cr>", desc = "File History", nowait = false, remap = false },
		
		-- Push/Pull 操作
		{ "<leader>sp", ":Git pull --rebase<cr>", desc = "Pull Rebase", nowait = false, remap = false },
		{ "<leader>sP", ":Git push<cr>", desc = "Push", nowait = false, remap = false },
		-- GitSigns 操作
		{ "<leader>sn", function() require('gitsigns').next_hunk() end, desc = "下一个变更块", nowait = false, remap = false },
		{ "<leader>sb", function() require('gitsigns').prev_hunk() end, desc = "上一个变更块", nowait = false, remap = false },
		{ "<leader>ss", function() require('gitsigns').stage_hunk() end, desc = "暂存变更块", nowait = false, remap = false },
		{ "<leader>sr", function() require('gitsigns').reset_hunk() end, desc = "撤销变更块", nowait = false, remap = false },
		{ "<leader>su", function() require('gitsigns').undo_stage_hunk() end, desc = "撤销暂存变更块", nowait = false, remap = false },
		{ "<leader>sh", function() require('gitsigns').preview_hunk() end, desc = "预览变更块", nowait = false, remap = false },
		{ "<leader>sB", function() require('gitsigns').blame_line{full=true} end, desc = "当前行 blame", nowait = false, remap = false },
		{ "<leader>st", function() require('gitsigns').toggle_current_line_blame() end, desc = "切换行 blame", nowait = false, remap = false },
		{ "<leader>sT", function() require('gitsigns').toggle_deleted() end, desc = "切换显示已删除行", nowait = false, remap = false },
		-- 文件对比功能 (恢复原功能，同时提供现代化选择)
		{ "<leader>se", function()
			local file = vim.api.nvim_buf_get_name(0)
			if file == "" then
				vim.notify("当前 buffer 没有关联文件", vim.log.levels.WARN)
				return
			end
			-- 获取 git 根目录
			local git_root = vim.fn.systemlist("git -C " .. vim.fn.fnameescape(vim.fn.expand("%:p:h")) .. " rev-parse --show-toplevel")[1]
			if not git_root or git_root == "" then
				vim.notify("未找到 git 仓库根目录", vim.log.levels.ERROR)
				return
			end
			-- 计算相对路径
			local relpath = file:sub(#git_root + 2)
			if relpath == "" then
				vim.notify("文件路径解析失败", vim.log.levels.ERROR)
				return
			end
			vim.cmd("tabnew")
			vim.cmd("edit " .. file)
			vim.cmd("vsplit")
			vim.cmd("wincmd j")
			vim.cmd("Gedit HEAD:" .. relpath)
			vim.cmd("wincmd k")
		end, desc = "新 tab split 并对比 HEAD", nowait = false, remap = false },
	}
	require("which-key").add(keymap)
end

return M
