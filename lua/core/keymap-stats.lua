-- ================================
-- Keymap 使用统计模块 (异步版本)
-- 完全异步，不影响正常使用
-- ================================
local M = {}

-- 数据文件路径
local data_dir = vim.fn.stdpath("data") .. "/keymap-stats"
local stats_file = data_dir .. "/stats.json"

-- 内存中的统计数据
local stats = { keymaps = {} }
local pending_records = {} -- 待写入的记录队列
local save_scheduled = false

-- 确保数据目录存在
local function ensure_dir()
	vim.fn.mkdir(data_dir, "p")
end

-- 异步加载统计数据
function M.load()
	ensure_dir()
	vim.schedule(function()
		local file = io.open(stats_file, "r")
		if file then
			local content = file:read("*a")
			file:close()
			local ok, data = pcall(vim.json.decode, content)
			if ok and data then
				stats = vim.tbl_deep_extend("force", stats, data)
			end
		end
	end)
end

-- 异步保存统计数据
local function async_save()
	if save_scheduled then
		return
	end
	save_scheduled = true

	vim.defer_fn(function()
		-- 先处理待写入队列
		local today = os.date("%Y-%m-%d")
		for _, rec in ipairs(pending_records) do
			local key_entry = stats.keymaps[rec.keymap] or {
				count = 0,
				first_used = today,
				last_used = today,
				daily = {},
				desc = rec.desc or "",
			}
			key_entry.count = key_entry.count + 1
			key_entry.last_used = today
			key_entry.daily[today] = (key_entry.daily[today] or 0) + 1
			if rec.desc then
				key_entry.desc = rec.desc
			end
			stats.keymaps[rec.keymap] = key_entry
		end
		pending_records = {}

		-- 异步写入文件
		ensure_dir()
		local file = io.open(stats_file, "w")
		if file then
			file:write(vim.json.encode(stats))
			file:close()
		end
		save_scheduled = false
	end, 2000) -- 2秒后批量保存
end

-- 记录一次快捷键使用（完全异步）
function M.record(keymap, desc)
	table.insert(pending_records, { keymap = keymap, desc = desc })
	async_save()
end

-- 获取今日统计
function M.today()
	local today = os.date("%Y-%m-%d")
	local list = {}
	for keymap, data in pairs(stats.keymaps) do
		local today_count = data.daily and data.daily[today] or 0
		if today_count > 0 then
			table.insert(list, { keymap = keymap, count = today_count, desc = data.desc })
		end
	end
	table.sort(list, function(a, b)
		return a.count > b.count
	end)
	return list
end

-- 获取使用频率最高的 N 个快捷键
function M.top(n)
	n = n or 20
	local list = {}
	for keymap, data in pairs(stats.keymaps) do
		table.insert(list, { keymap = keymap, count = data.count, desc = data.desc, last_used = data.last_used })
	end
	table.sort(list, function(a, b)
		return a.count > b.count
	end)
	return vim.list_slice(list, 1, n)
end

-- 获取最近 N 天未使用的快捷键
function M.unused(days)
	days = days or 30
	local cutoff = os.time() - (days * 24 * 60 * 60)
	local list = {}
	for keymap, data in pairs(stats.keymaps) do
		local last = data.last_used
		if last then
			local y, m, d = last:match("(%d+)-(%d+)-(%d+)")
			if y then
				local last_time = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d) })
				if last_time < cutoff then
					table.insert(list, { keymap = keymap, count = data.count, desc = data.desc, last_used = last })
				end
			end
		end
	end
	table.sort(list, function(a, b)
		return a.last_used < b.last_used
	end)
	return list
end

-- 显示统计报告
function M.show_report()
	local lines = { "# Keymap 使用统计", "", "## 今日 Top 20" }

	local today_stats = M.today()
	if #today_stats == 0 then
		table.insert(lines, "_今日暂无记录_")
	else
		for i, item in ipairs(today_stats) do
			if i > 20 then
				break
			end
			table.insert(lines, string.format("%2d. `%s` (%d) %s", i, item.keymap, item.count, item.desc or ""))
		end
	end

	table.insert(lines, "")
	table.insert(lines, "## 总使用 Top 20")
	for i, item in ipairs(M.top(20)) do
		table.insert(lines, string.format("%2d. `%s` (%d, %s) %s", i, item.keymap, item.count, item.last_used or "", item.desc or ""))
	end

	table.insert(lines, "")
	table.insert(lines, "## 30天未使用")
	local unused = M.unused(30)
	if #unused == 0 then
		table.insert(lines, "_无_")
	else
		for _, item in ipairs(unused) do
			table.insert(lines, string.format("- `%s` (%s) %s", item.keymap, item.last_used, item.desc or ""))
		end
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].filetype = "markdown"

	local width = math.floor(vim.o.columns * 0.7)
	local height = math.floor(vim.o.lines * 0.7)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		style = "minimal",
		border = "rounded",
		title = " Keymap Stats ",
		title_pos = "center",
	})

	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf })
end

-- 检测冲突
function M.detect_conflicts()
	local all_maps = {}
	local conflicts = {}

	for _, mode in ipairs({ "n", "v", "i", "t" }) do
		for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
			local key = mode .. ":" .. map.lhs
			if all_maps[key] then
				table.insert(conflicts, { mode = mode, lhs = map.lhs })
			else
				all_maps[key] = true
			end
		end
	end
	return conflicts
end

function M.show_conflicts()
	local conflicts = M.detect_conflicts()
	if #conflicts == 0 then
		vim.notify("无冲突", vim.log.levels.INFO)
	else
		local msg = "检测到冲突:\n"
		for _, c in ipairs(conflicts) do
			msg = msg .. string.format("[%s] %s\n", c.mode, c.lhs)
		end
		vim.notify(msg, vim.log.levels.WARN)
	end
end

-- Hook vim.keymap.set 来自动记录
local original_keymap_set = vim.keymap.set
local hooked = false

function M.hook_keymap_set()
	if hooked then
		return
	end
	hooked = true

	vim.keymap.set = function(mode, lhs, rhs, opts)
		opts = opts or {}
		local desc = opts.desc or ""
		local original_rhs = rhs

		-- 只 hook 有 desc 的 keymap（通常是用户定义的）
		if desc ~= "" and type(rhs) == "function" then
			rhs = function()
				M.record(lhs, desc)
				return original_rhs()
			end
		elseif desc ~= "" and type(rhs) == "string" and not rhs:match("^<Plug>") and not rhs:match("^<Cmd>") then
			local wrapped = function()
				M.record(lhs, desc)
				local keys = vim.api.nvim_replace_termcodes(original_rhs, true, false, true)
				vim.api.nvim_feedkeys(keys, "m", false)
			end
			return original_keymap_set(mode, lhs, wrapped, opts)
		end

		return original_keymap_set(mode, lhs, rhs, opts)
	end
end

-- Hook which-key.add 来记录通过 which-key 注册的 keymap
function M.hook_which_key()
	-- 延迟到 which-key 加载后再 hook
	vim.api.nvim_create_autocmd("User", {
		pattern = "LazyLoad",
		callback = function(event)
			if event.data == "which-key.nvim" then
				local ok, wk = pcall(require, "which-key")
				if not ok then
					return
				end

				local original_add = wk.add
				wk.add = function(mappings, opts)
					-- 包装每个 mapping 的回调
					for _, mapping in ipairs(mappings) do
						local lhs = mapping[1]
						local rhs = mapping[2]
						local desc = mapping.desc or ""

						if lhs and rhs and desc ~= "" and type(rhs) == "function" then
							local original_fn = rhs
							mapping[2] = function()
								M.record(lhs, desc)
								return original_fn()
							end
						elseif lhs and rhs and desc ~= "" and type(rhs) == "string" then
							local original_cmd = rhs
							mapping[2] = function()
								M.record(lhs, desc)
								vim.cmd(original_cmd:gsub("^:", ""))
							end
						end
					end
					return original_add(mappings, opts)
				end
			end
		end,
	})
end

function M.setup()
	M.load()
	M.hook_keymap_set()
	M.hook_which_key()

	vim.api.nvim_create_autocmd("VimLeavePre", {
		callback = function()
			-- 同步保存剩余数据
			local today = os.date("%Y-%m-%d")
			for _, rec in ipairs(pending_records) do
				local key_entry = stats.keymaps[rec.keymap] or { count = 0, daily = {} }
				key_entry.count = key_entry.count + 1
				key_entry.last_used = today
				key_entry.daily[today] = (key_entry.daily[today] or 0) + 1
				stats.keymaps[rec.keymap] = key_entry
			end
			ensure_dir()
			local file = io.open(stats_file, "w")
			if file then
				file:write(vim.json.encode(stats))
				file:close()
			end
		end,
	})

	vim.api.nvim_create_user_command("KeymapStats", M.show_report, {})
	vim.api.nvim_create_user_command("KeymapConflicts", M.show_conflicts, {})
end

return M
