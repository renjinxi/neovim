local M = {}

local function get_project_root()
	local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null")
	if git_root ~= "" then
		return git_root:gsub("%s+", "")
	end
	return nil
end

local function copy_to_clipboard(content, notify_message)
	if not content or content == "" then
		vim.notify("没有内容可复制", vim.log.levels.WARN)
		return
	end
	if os.getenv("SSH_CLIENT") or os.getenv("SSH_TTY") then
		local text = content:gsub("\n$", "")
		local osc52 = string.format("\027]52;c;%s\007", vim.base64.encode(text))
		io.stdout:write(osc52)
		io.stdout:flush()
		vim.notify("已通过OSC52" .. notify_message, vim.log.levels.INFO)
	else
		vim.fn.setreg("+", content)
		vim.notify("已" .. notify_message, vim.log.levels.INFO)
	end
end

function M.create_new_file()
	local current_directory = vim.fn.expand("%:p:h")
	local directory = current_directory ~= "" and current_directory or get_project_root()
	if not directory then
		print("Error: No project root found.")
		return
	end
	vim.ui.input({
		prompt = "New File Name (in " .. directory .. "): ",
		default = directory .. "/",
	}, function(new_name)
		if not new_name or new_name == "" then
			return
		end
		local dir = new_name:match("(.*/)")
		if dir and not vim.loop.fs_stat(dir) then
			os.execute("mkdir -p " .. dir)
		end
		local file = io.open(new_name, "w")
		if file then
			file:close()
			vim.cmd("e " .. new_name)
			print("File created: " .. new_name)
		end
	end)
end

function M.rename_current_file()
	local old_path = vim.fn.expand("%:p")
	vim.ui.input({
		prompt = "New Path and Name: ",
		default = old_path,
	}, function(new_path)
		if not new_path or new_path == "" then
			return
		end
		local dir = new_path:match("(.*/)")
		if dir and not vim.loop.fs_stat(dir) then
			os.execute("mkdir -p " .. dir)
		end
		local success, err = os.rename(old_path, new_path)
		if success then
			vim.cmd("e " .. new_path)
			print("File renamed to " .. new_path)
		else
			print("Error renaming file: " .. err)
		end
	end)
end

function M.open_project_in_new_tab()
	local input = vim.fn.input("Tab Name: ")
	if input ~= "" then
		vim.cmd("tabnew")
		vim.cmd("Telescope projects")
		vim.cmd("LualineRenameTab " .. input)
	end
end

function M.toggle_neovide()
	vim.g.neovide_fullscreen = not vim.g.neovide_fullscreen
end

function M.toggle_hlsearch()
	vim.o.hlsearch = not vim.o.hlsearch
end

function M.copy_message()
	copy_to_clipboard(vim.fn.getreg("+"), "复制消息内容到剪贴板")
end

function M.copy_last_message()
	local messages = vim.api.nvim_exec2("messages", { output = true })
	local lines = vim.split(messages.output, "\n")
	for i = #lines, 1, -1 do
		if lines[i] ~= "" then
			copy_to_clipboard(lines[i], "复制最后一条消息到剪贴板")
			return
		end
	end
end

function M.copy_all_messages()
	local messages = vim.api.nvim_exec2("messages", { output = true })
	copy_to_clipboard(messages.output, "复制所有消息到剪贴板")
end

function M.copy_file_path()
	local file_path = vim.fn.expand("%:p")
	copy_to_clipboard(file_path, "复制文件路径到剪贴板: " .. file_path)
end

function M.copy_word_with_location()
	local word = vim.fn.expand("<cword>")
	local file_path = vim.fn.expand("%:p")
	local line_num = vim.fn.line(".")
	local content = string.format("%s:%d:%s", file_path, line_num, word)
	copy_to_clipboard(content, "复制 word 和位置信息到剪贴板")
end

function M.copy_selection_with_location()
	local mode = vim.fn.mode()
	local start_line, end_line
	local is_visual = false

	if mode == "v" or mode == "V" or mode == "\22" then
		is_visual = true
		start_line = vim.fn.line("v")
		end_line = vim.fn.line(".")
		if start_line > end_line then
			start_line, end_line = end_line, start_line
		end
	else
		start_line = vim.fn.line(".")
		end_line = start_line
	end

	local file_path = vim.fn.expand("%:p")
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	local selected_text = table.concat(lines, "\n")

	local location_info
	if start_line == end_line then
		location_info = string.format("%s:%d", file_path, start_line)
	else
		location_info = string.format("%s:%d-%d", file_path, start_line, end_line)
	end

	local content = string.format("%s\n\n%s", location_info, selected_text)

	if is_visual then
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
	end

	copy_to_clipboard(content, "复制内容和位置信息到剪贴板")
end

function M.open_path_at_cursor()
	local current_line = vim.api.nvim_get_current_line()
	local cursor_col = vim.api.nvim_win_get_cursor(0)[2] + 1
	local patterns = { "[^%s:]+:%d+:%d+", "[^%s:]+:%d+" }
	local match = nil
	for _, pattern in ipairs(patterns) do
		local start_col = 1
		while true do
			local s, e = current_line:find(pattern, start_col)
			if not s then
				break
			end
			if cursor_col >= s and cursor_col <= e then
				match = current_line:sub(s, e)
				break
			end
			start_col = e + 1
		end
		if match then
			break
		end
	end
	if not match then
		vim.notify("未在光标附近找到 path:line", vim.log.levels.WARN)
		return
	end
	match = match:gsub("[,.;]+$", "")
	local path_part, line_str, col_str = match:match("^([^:]+):(%d+):?(%d*)$")
	if not path_part then
		vim.notify("无法解析路径: " .. match, vim.log.levels.WARN)
		return
	end

	local target_path = path_part
	if path_part:sub(1, 1) == "~" then
		target_path = vim.fn.expand(path_part)
	elseif not path_part:match("^/") then
		local project_root = get_project_root()
		if project_root then
			local candidate = vim.fn.fnamemodify(project_root .. "/" .. path_part, ":p")
			if vim.fn.filereadable(candidate) == 1 then
				target_path = candidate
			end
		end
	end
	if vim.fn.filereadable(target_path) == 0 then
		vim.notify("文件不存在: " .. target_path, vim.log.levels.ERROR)
		return
	end
	vim.cmd("edit " .. vim.fn.fnameescape(target_path))
	local line_num = tonumber(line_str) or 1
	local col_num = tonumber(col_str)
	vim.api.nvim_win_set_cursor(0, { line_num, col_num and col_num - 1 or 0 })
end

function M.reload_config()
	local ok, reload = pcall(require, "core.reload")
	if ok then
		reload.reload_config()
	else
		vim.notify("无法加载 reload 模块", vim.log.levels.ERROR)
	end
end

function M.tab_rename()
	vim.ui.input({ prompt = "Tab name: " }, function(name)
		if name and name ~= "" then
			vim.t.tab_name = name
			vim.cmd.redrawtabline()
		end
	end)
end

function M.tab_clear_name()
	vim.t.tab_name = nil
	vim.cmd.redrawtabline()
end

function M.telescope_copy_file_content()
	require("telescope.builtin").find_files({
		prompt_title = "Copy File Content",
		attach_mappings = function(prompt_bufnr, map)
			local actions = require("telescope.actions")
			local action_state = require("telescope.actions.state")
			map("i", "<CR>", function()
				local selection = action_state.get_selected_entry()
				actions.close(prompt_bufnr)
				if selection then
					local file_path = selection.path or selection.value
					local file_content = vim.fn.readfile(file_path)
					local row = vim.api.nvim_win_get_cursor(0)[1]
					vim.api.nvim_buf_set_lines(0, row, row, false, file_content)
					print("File content copied: " .. file_path)
				end
			end)
			return true
		end,
	})
end

return M
