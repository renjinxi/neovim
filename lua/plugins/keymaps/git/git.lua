local M = {}

-- 记住上次选择的仓库
local last_selected_repo = nil

-- 直接打开上次的仓库
local function lazygit_last_repo()
	if not last_selected_repo then
		vim.notify("还没有选择过仓库，请先使用 <leader>sL 选择", vim.log.levels.WARN)
		return
	end

	-- 获取绝对路径
	local abs_path = vim.fn.fnamemodify(last_selected_repo, ":p")

	-- 使用 toggleterm 打开 lazygit
	local Terminal = require("toggleterm.terminal").Terminal
	local lazygit = Terminal:new({
		cmd = "lazygit",
		dir = abs_path,
		direction = "float",
		float_opts = {
			border = "curved",
		},
		on_open = function(term)
			vim.cmd("startinsert!")
		end,
	})
	lazygit:toggle()
end

-- 多仓库 LazyGit 选择器
local function lazygit_multi_repo()
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	-- 查找所有包含 .git 的子目录
	local git_dirs = vim.fn.systemlist("find . -maxdepth 3 -type d -name '.git' 2>/dev/null | sed 's|/.git||' | sort")

	if #git_dirs == 0 then
		vim.notify("未找到任何 git 仓库", vim.log.levels.WARN)
		return
	end

	-- 找到上次选择的仓库的索引
	local default_selection = 1
	if last_selected_repo then
		for i, dir in ipairs(git_dirs) do
			if dir == last_selected_repo then
				default_selection = i
				break
			end
		end
	end

	pickers.new({}, {
		prompt_title = "选择 Git 仓库" .. (last_selected_repo and " (默认: " .. last_selected_repo:gsub("^%./", "") .. ")" or ""),
		finder = finders.new_table({
			results = git_dirs,
			entry_maker = function(entry)
				local display = entry:gsub("^%./", "") -- 移除 ./ 前缀
				-- 如果是上次选择的仓库，添加标记
				if entry == last_selected_repo then
					display = "★ " .. display
				end
				return {
					value = entry,
					display = display,
					ordinal = display,
				}
			end,
		}),
		sorter = conf.generic_sorter({}),
		default_selection_index = default_selection,
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				if selection then
					-- 记住这次的选择
					last_selected_repo = selection.value

					-- 获取绝对路径
					local abs_path = vim.fn.fnamemodify(selection.value, ":p")

					-- 使用 toggleterm 打开 lazygit
					local Terminal = require("toggleterm.terminal").Terminal
					local lazygit = Terminal:new({
						cmd = "lazygit",
						dir = abs_path,
						direction = "float",
						float_opts = {
							border = "curved",
						},
						on_open = function(term)
							vim.cmd("startinsert!")
						end,
					})
					lazygit:toggle()
				end
			end)
			return true
		end,
	}):find()
end

function M.setup()
	local keymap = {
		-- Git 工具组 (多种选择)
		{ "<leader>s", group = "Git", nowait = false, remap = false },

		-- 三种Git界面选择
		{ "<leader>sg", ":Neogit<cr>", desc = "Neogit (现代界面)", nowait = false, remap = false },
		{ "<leader>sl", ":LazyGit<cr>", desc = "LazyGit (当前目录)", nowait = false, remap = false },
		{ "<leader>sL", lazygit_multi_repo, desc = "LazyGit (选择仓库)", nowait = false, remap = false },
		{ "<leader>sk", lazygit_last_repo, desc = "LazyGit (上次仓库)", nowait = false, remap = false },
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
