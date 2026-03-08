local M = {}

function M.setup(opts)
	local api = {}
	local terminal = assert(opts.terminal, "git module requires terminal")

	local last_selected_repo = nil
	local multi_repo_state = { buf = nil, win = nil, items = {} }

	local function open_lazygit_float(dir)
		local width = math.floor(vim.o.columns * 0.9)
		local height = math.floor(vim.o.lines * 0.9)
		local row = math.floor((vim.o.lines - height) / 2)
		local col = math.floor((vim.o.columns - width) / 2)

		local buf = vim.api.nvim_create_buf(false, true)
		local win = vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			width = width,
			height = height,
			row = row,
			col = col,
			style = "minimal",
			border = "rounded",
			title = " Lazygit ",
			title_pos = "center",
		})

		terminal.termopen({
			cmd = "lazygit",
			cwd = dir,
		}, {
			on_exit = function()
				pcall(vim.api.nvim_win_close, win, true)
			end,
		})
		vim.cmd("startinsert")
	end

	local function get_multi_repo_branches()
		local cwd = vim.fn.getcwd()
		local repos = {}

		local current_branch = vim.fn.system("git -C " .. vim.fn.shellescape(cwd) .. " branch --show-current 2>/dev/null"):gsub("%s+", "")
		if current_branch ~= "" then
			local repo_name = vim.fn.fnamemodify(cwd, ":t")
			table.insert(repos, { name = repo_name, branch = current_branch, path = cwd })
		end

		local subdirs = vim.fn.glob(cwd .. "/*/.git", false, true)
		for _, git_dir in ipairs(subdirs) do
			local repo_path = vim.fn.fnamemodify(git_dir, ":h")
			local repo_name = vim.fn.fnamemodify(repo_path, ":t")
			local branch = vim.fn.system("git -C " .. vim.fn.shellescape(repo_path) .. " branch --show-current 2>/dev/null"):gsub("%s+", "")
			if branch ~= "" then
				table.insert(repos, { name = repo_name, branch = branch, path = repo_path })
			end
		end

		return repos
	end

	local function select_repo_and_run(callback, prompt_title)
		local git_dirs = vim.fn.systemlist("find . -maxdepth 3 -type d -name '.git' 2>/dev/null | sed 's|/.git||' | sort")
		if #git_dirs == 0 then
			vim.notify("未找到任何 git 仓库", vim.log.levels.WARN)
			return
		end
		if #git_dirs == 1 then
			callback(vim.fn.fnamemodify(git_dirs[1], ":p"))
			return
		end
		require("telescope.pickers").new({}, {
			prompt_title = prompt_title or "选择 Git 仓库",
			finder = require("telescope.finders").new_table({
				results = git_dirs,
				entry_maker = function(entry)
					local display = entry:gsub("^%./", "")
					if entry == last_selected_repo then
						display = "★ " .. display
					end
					return { value = entry, display = display, ordinal = display }
				end,
			}),
			sorter = require("telescope.config").values.generic_sorter({}),
			attach_mappings = function(prompt_bufnr)
				require("telescope.actions").select_default:replace(function()
					require("telescope.actions").close(prompt_bufnr)
					local selection = require("telescope.actions.state").get_selected_entry()
					if selection then
						last_selected_repo = selection.value
						callback(vim.fn.fnamemodify(selection.value, ":p"))
					end
				end)
				return true
			end,
		}):find()
	end

	local function close_multi_repo_viewer()
		if multi_repo_state.win and vim.api.nvim_win_is_valid(multi_repo_state.win) then
			vim.api.nvim_win_close(multi_repo_state.win, true)
		end
		multi_repo_state.win = nil
	end

	local function render_multi_repo_viewer(repos_with_changes, total_repos)
		local lines = {}
		local items = {}
		local total_changes = 0

		for _, repo_data in ipairs(repos_with_changes) do
			local repo_name = vim.fn.fnamemodify(repo_data.path, ":t")
			if #repo_data.changes > 0 then
				table.insert(lines, "")
				table.insert(items, { type = "header" })
				table.insert(lines, string.format("## %s (%d)", repo_name, #repo_data.changes))
				table.insert(items, { type = "repo", path = repo_data.path })

				for _, change in ipairs(repo_data.changes) do
					local icon = change.status == "M" and "~" or (change.status == "A" and "+" or (change.status == "D" and "-" or "?"))
					table.insert(lines, string.format("   %s %s", icon, change.file))
					table.insert(items, { type = "file", status = change.status, file = change.file, repo = repo_data.path })
					total_changes = total_changes + 1
				end
			end
		end

		if total_changes == 0 then
			vim.notify("All repos are clean!", vim.log.levels.INFO)
			return
		end

		table.insert(lines, "")
		table.insert(items, { type = "footer" })
		table.insert(lines, "─────────────────────────────────────────────────────────")
		table.insert(items, { type = "footer" })
		table.insert(lines, string.format(" Total: %d repos, %d changes", total_repos, total_changes))
		table.insert(items, { type = "footer" })
		table.insert(lines, "")
		table.insert(items, { type = "footer" })
		table.insert(lines, " [Enter] open  [d] diff  [D] repo diff  [g] lazygit  [q] close")
		table.insert(items, { type = "footer" })

		multi_repo_state.items = items

		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		vim.api.nvim_buf_set_option(buf, "modifiable", false)
		vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
		vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

		local width = math.min(70, vim.o.columns - 10)
		local height = math.min(#lines + 2, vim.o.lines - 10)
		local win = vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			width = width,
			height = height,
			row = math.floor((vim.o.lines - height) / 2),
			col = math.floor((vim.o.columns - width) / 2),
			style = "minimal",
			border = "rounded",
			title = " Multi-Repo Changes ",
			title_pos = "center",
		})

		multi_repo_state.buf = buf
		multi_repo_state.win = win

		vim.api.nvim_win_set_option(win, "cursorline", true)
		vim.api.nvim_win_set_option(win, "wrap", false)

		local map_opts = { buffer = buf, noremap = true, silent = true }
		vim.keymap.set("n", "q", close_multi_repo_viewer, map_opts)
		vim.keymap.set("n", "<Esc>", close_multi_repo_viewer, map_opts)

		vim.keymap.set("n", "<CR>", function()
			local item = items[vim.api.nvim_win_get_cursor(win)[1]]
			if item and item.type == "file" then
				close_multi_repo_viewer()
				vim.cmd("edit " .. item.repo .. "/" .. item.file)
			end
		end, map_opts)

		vim.keymap.set("n", "d", function()
			local item = items[vim.api.nvim_win_get_cursor(win)[1]]
			if item and item.type == "file" then
				vim.cmd("DiffviewOpen -C" .. item.repo .. " -- " .. item.file)
			end
		end, map_opts)

		vim.keymap.set("n", "D", function()
			local item = items[vim.api.nvim_win_get_cursor(win)[1]]
			local repo_path = item and (item.type == "file" and item.repo or item.path) or nil
			if repo_path then
				vim.cmd("DiffviewOpen -C" .. repo_path)
			end
		end, map_opts)

		vim.keymap.set("n", "g", function()
			local item = items[vim.api.nvim_win_get_cursor(win)[1]]
			local repo_path = item and (item.type == "file" and item.repo or item.path) or nil
			if repo_path then
				open_lazygit_float(repo_path)
			end
		end, map_opts)

		for i, item in ipairs(items) do
			if item.type == "file" then
				vim.api.nvim_win_set_cursor(win, { i, 0 })
				break
			end
		end
	end

	function api.open_lazygit_float(dir)
		open_lazygit_float(dir)
	end

	function api.show_multi_repo_branches()
		local repos = get_multi_repo_branches()
		if #repos == 0 then
			vim.notify("当前目录下没有 git 仓库", vim.log.levels.WARN)
			return
		end

		local lines = { "  Git Repositories Branches", "  " .. string.rep("─", 40) }
		for _, repo in ipairs(repos) do
			local status_cmd = "git -C " .. vim.fn.shellescape(repo.path) .. " status --porcelain 2>/dev/null | wc -l"
			local changes = vim.fn.system(status_cmd):gsub("%s+", "")
			local change_indicator = tonumber(changes) > 0 and " ✱" or ""
			table.insert(lines, string.format("  %s: %s%s", repo.name, repo.branch, change_indicator))
			table.insert(lines, string.format("    %s", repo.path:gsub(vim.fn.expand("~"), "~")))
		end
		table.insert(lines, "")
		table.insert(lines, "  [q] 关闭  [g] 刷新  [enter] 打开 lazygit")

		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
		vim.bo[buf].modifiable = false
		vim.bo[buf].buftype = "nofile"
		vim.bo[buf].bufhidden = "wipe"

		local width = 50
		local height = #lines
		local win = vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			width = width,
			height = height,
			row = math.floor((vim.o.lines - height) / 2),
			col = math.floor((vim.o.columns - width) / 2),
			style = "minimal",
			border = "rounded",
			title = " Multi-Repo Branches ",
			title_pos = "center",
		})

		vim.api.nvim_buf_add_highlight(buf, -1, "Title", 0, 0, -1)
		for i = 2, #lines - 2 do
			vim.api.nvim_buf_add_highlight(buf, -1, i % 2 == 1 and "Function" or "Comment", i, 0, -1)
		end
		vim.api.nvim_buf_add_highlight(buf, -1, "Comment", #lines - 1, 0, -1)

		local function close_win()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
		end

		vim.keymap.set("n", "q", close_win, { buffer = buf, nowait = true })
		vim.keymap.set("n", "<Esc>", close_win, { buffer = buf, nowait = true })
		vim.keymap.set("n", "g", function()
			close_win()
			api.show_multi_repo_branches()
		end, { buffer = buf, nowait = true })
		vim.keymap.set("n", "<CR>", function()
			local repo_idx = math.floor((vim.api.nvim_win_get_cursor(win)[1] - 2) / 2) + 1
			if repos[repo_idx] then
				close_win()
				open_lazygit_float(repos[repo_idx].path)
			end
		end, { buffer = buf, nowait = true })
	end

	function api.git_lazygit_last_repo()
		if not last_selected_repo then
			vim.notify("还没有选择过仓库", vim.log.levels.WARN)
			return
		end
		open_lazygit_float(vim.fn.fnamemodify(last_selected_repo, ":p"))
	end

	function api.git_lazygit_multi_repo()
		local git_dirs = vim.fn.systemlist("find . -maxdepth 3 -type d -name '.git' 2>/dev/null | sed 's|/.git||' | sort")
		if #git_dirs == 0 then
			vim.notify("未找到任何 git 仓库", vim.log.levels.WARN)
			return
		end
		require("telescope.pickers").new({}, {
			prompt_title = "选择 Git 仓库",
			finder = require("telescope.finders").new_table({
				results = git_dirs,
				entry_maker = function(entry)
					local display = entry:gsub("^%./", "")
					if entry == last_selected_repo then
						display = "★ " .. display
					end
					return { value = entry, display = display, ordinal = display }
				end,
			}),
			sorter = require("telescope.config").values.generic_sorter({}),
			attach_mappings = function(prompt_bufnr)
				require("telescope.actions").select_default:replace(function()
					require("telescope.actions").close(prompt_bufnr)
					local selection = require("telescope.actions.state").get_selected_entry()
					if selection then
						last_selected_repo = selection.value
						open_lazygit_float(vim.fn.fnamemodify(selection.value, ":p"))
					end
				end)
				return true
			end,
		}):find()
	end

	function api.gitlab_with_repo(action)
		select_repo_and_run(function(repo_path)
			vim.cmd("cd " .. vim.fn.fnameescape(repo_path))
			vim.defer_fn(function()
				local ok, gitlab = pcall(require, "gitlab")
				if not ok then
					return
				end
				if action == "create_mr" then
					gitlab.create_mr()
				elseif action == "review" then
					gitlab.review()
				elseif action == "summary" then
					gitlab.summary()
				elseif action == "choose_merge_request" then
					gitlab.choose_merge_request()
				elseif action == "pipeline" then
					gitlab.pipeline()
				elseif action == "open_in_browser" then
					gitlab.open_in_browser()
				end
			end, 100)
		end, "选择仓库 - GitLab " .. action)
	end

	function api.gitlab_create_mr_web(target_branch)
		local branch = vim.fn.systemlist("git branch --show-current")[1]
		if not branch or branch == "" then
			vim.notify("[MR] 未找到当前分支，请确认在 git 仓库内", vim.log.levels.ERROR)
			return
		end
		local remote_url = vim.fn.systemlist("git remote get-url origin")[1] or ""
		if remote_url == "" then
			vim.notify("[MR] git remote get-url origin 返回空，请检查 remote 配置", vim.log.levels.ERROR)
			return
		end
		local base_url = remote_url
			:gsub("%.git$", "")
			:gsub("^git@([^:]+):", "https://%1/")
			:gsub("^ssh://git@", "https://")
		if base_url == "" then
			vim.notify("[MR] 无法解析远程 URL: " .. remote_url, vim.log.levels.ERROR)
			return
		end
		local target = (target_branch and target_branch ~= "") and target_branch or "main"
		local url = base_url .. "/-/merge_requests/new?merge_request[source_branch]=" .. branch
			.. "&merge_request[target_branch]=" .. target
		local open_cmd = vim.fn.has("mac") == 1 and "open" or "xdg-open"
		vim.notify(("[MR] %s → %s\n%s"):format(branch, target, url), vim.log.levels.INFO)
		vim.fn.jobstart({ open_cmd, url }, {
			detach = true,
			on_stderr = function(_, data)
				local msg = table.concat(data, "\n")
				if msg ~= "" then
					vim.schedule(function()
						vim.notify("[MR] 打开浏览器失败: " .. msg, vim.log.levels.ERROR)
					end)
				end
			end,
		})
	end

	function api.git_compare_head()
		local file = vim.api.nvim_buf_get_name(0)
		if file == "" then
			vim.notify("当前 buffer 没有关联文件", vim.log.levels.WARN)
			return
		end
		local git_root = vim.fn.systemlist("git -C " .. vim.fn.fnameescape(vim.fn.expand("%:p:h")) .. " rev-parse --show-toplevel")[1]
		if not git_root or git_root == "" then
			vim.notify("未找到 git 仓库根目录", vim.log.levels.ERROR)
			return
		end
		local relpath = file:sub(#git_root + 2)
		vim.cmd("tabnew")
		vim.cmd("edit " .. file)
		vim.cmd("vsplit")
		vim.cmd("wincmd j")
		vim.cmd("Gedit HEAD:" .. relpath)
		vim.cmd("wincmd k")
	end

	function api.diffview_multi_repo()
		local cwd = vim.fn.getcwd()
		vim.notify("Scanning repos...", vim.log.levels.INFO)
		vim.system({ "find", cwd, "-maxdepth", "2", "-name", ".git" }, { text = true }, function(find_result)
			if find_result.code ~= 0 or not find_result.stdout or find_result.stdout == "" then
				vim.schedule(function()
					vim.notify("No git repos found in " .. cwd, vim.log.levels.WARN)
				end)
				return
			end

			local repos = {}
			for line in find_result.stdout:gmatch("[^\n]+") do
				table.insert(repos, line:gsub("/.git$", ""))
			end
			if #repos == 0 then
				vim.schedule(function()
					vim.notify("No git repos found in " .. cwd, vim.log.levels.WARN)
				end)
				return
			end

			local repos_with_changes = {}
			local pending = #repos
			for _, repo_path in ipairs(repos) do
				vim.system({ "git", "-C", repo_path, "status", "--porcelain" }, { text = true }, function(status_result)
					local changes = {}
					if status_result.code == 0 and status_result.stdout then
						for line in status_result.stdout:gmatch("[^\n]+") do
							if line ~= "" then
								table.insert(changes, {
									status = line:sub(1, 2):gsub("%s", ""),
									file = line:sub(4),
								})
							end
						end
					end
					table.insert(repos_with_changes, { path = repo_path, changes = changes })
					pending = pending - 1
					if pending == 0 then
						vim.schedule(function()
							table.sort(repos_with_changes, function(a, b)
								return a.path < b.path
							end)
							render_multi_repo_viewer(repos_with_changes, #repos)
						end)
					end
				end)
			end
		end)
	end

	function api.diffview_multi_repo_status()
		local cwd = vim.fn.getcwd()
		vim.system({ "find", cwd, "-maxdepth", "2", "-name", ".git" }, { text = true }, function(find_result)
			if find_result.code ~= 0 or not find_result.stdout or find_result.stdout == "" then
				vim.schedule(function()
					vim.notify("No git repos found in " .. cwd, vim.log.levels.WARN)
				end)
				return
			end

			local repos = {}
			for line in find_result.stdout:gmatch("[^\n]+") do
				table.insert(repos, line:gsub("/.git$", ""))
			end
			if #repos == 0 then
				vim.schedule(function()
					vim.notify("No git repos found in " .. cwd, vim.log.levels.WARN)
				end)
				return
			end

			local results = {}
			local pending = #repos
			for _, repo_path in ipairs(repos) do
				vim.system({ "git", "-C", repo_path, "status", "--porcelain" }, { text = true }, function(status_result)
					local count = 0
					if status_result.code == 0 and status_result.stdout then
						for _ in status_result.stdout:gmatch("[^\n]+") do
							count = count + 1
						end
					end
					table.insert(results, { path = repo_path, count = count })
					pending = pending - 1
					if pending == 0 then
						vim.schedule(function()
							table.sort(results, function(a, b)
								return a.path < b.path
							end)

							local lines = { "# Git Repos Status", "" }
							local total_changes = 0
							for _, r in ipairs(results) do
								local name = vim.fn.fnamemodify(r.path, ":t")
								if r.count > 0 then
									table.insert(lines, string.format("  %s: %d changes", name, r.count))
									total_changes = total_changes + r.count
								else
									table.insert(lines, string.format("  %s: clean", name))
								end
							end
							table.insert(lines, "")
							table.insert(lines, string.format("Total: %d repos, %d changes", #repos, total_changes))

							local buf = vim.api.nvim_create_buf(false, true)
							vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
							vim.api.nvim_buf_set_option(buf, "modifiable", false)

							local width = 50
							local height = #lines + 2
							local win = vim.api.nvim_open_win(buf, true, {
								relative = "editor",
								width = width,
								height = height,
								row = math.floor((vim.o.lines - height) / 2),
								col = math.floor((vim.o.columns - width) / 2),
								style = "minimal",
								border = "rounded",
								title = " Multi-Repo Status ",
								title_pos = "center",
							})

							vim.keymap.set("n", "q", function()
								vim.api.nvim_win_close(win, true)
							end, { buffer = buf })
							vim.keymap.set("n", "<Esc>", function()
								vim.api.nvim_win_close(win, true)
							end, { buffer = buf })
						end)
					end
				end)
			end
		end)
	end

	return api
end

return M
