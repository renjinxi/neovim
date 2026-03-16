--- 频道 UI 层：buffer/window 管理、消息渲染、winbar
local ChannelView = {}
ChannelView.__index = ChannelView

--- @param channel table Channel 实例
function ChannelView.new(channel)
	local self = setmetatable({
		channel = channel,
		buf = nil,
		win = nil,
		input_buf = nil,
		input_win = nil,
	}, ChannelView)

	-- 订阅频道事件
	channel:on("message", function(msg, gap)
		self:_render_message(msg, gap)
	end)
	channel:on("state_changed", function()
		self:_refresh_winbar()
	end)

	return self
end

--- 截断字符串
local function truncate(s, max)
	if not s then return "" end
	if #s <= max then return s end
	return s:sub(1, max - 1) .. "…"
end

local function format_gap(gap)
	if not gap then return nil end
	if gap >= 60 then
		return string.format("+%dm%02ds", math.floor(gap / 60), gap % 60)
	end
	if gap >= 2 then
		return string.format("+%ds", gap)
	end
	return nil
end

local function looks_like_code(content)
	if content:find("```", 1, true) then return false end
	if content:find("\t", 1, true) then return true end
	if content:find("^%s*[%w_%.]+%s*=%s*") then return true end
	if content:find("^%s*local%s+[%w_]+") then return true end
	if content:find("\n", 1, true) then
		local code_lines = 0
		for _, line in ipairs(vim.split(content, "\n", { plain = true })) do
			if line:find("^%s*[%w_%.]+%s*=%s*")
				or line:find("^%s*local%s+[%w_]+")
				or line:find("^%s*[%w_%.]+%b()%s*$")
				or line:find("^%s*[{}%[%]();,]+%s*$") then
				code_lines = code_lines + 1
			end
		end
		if code_lines >= 2 then return true end
	end
	return false
end

local function render_markdown_content(content)
	local lines = vim.split(content, "\n", { plain = true })
	if looks_like_code(content) then
		return vim.list_extend({ "```" }, vim.list_extend(lines, { "```" }))
	end
	return lines
end

--- 打开频道 UI
function ChannelView:open()
	local channel = self.channel

	-- 主 buffer
	self.buf = vim.api.nvim_create_buf(false, true)
	vim.bo[self.buf].buftype = "nofile"
	vim.bo[self.buf].bufhidden = "hide"
	vim.bo[self.buf].swapfile = false
	vim.bo[self.buf].filetype = "markdown"
	pcall(vim.api.nvim_buf_set_name, self.buf, "acp://bus/" .. os.time())

	-- 输入 buffer
	self.input_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[self.input_buf].buftype = "nofile"
	vim.bo[self.input_buf].bufhidden = "hide"
	vim.bo[self.input_buf].swapfile = false

	-- 布局
	local width = math.floor(vim.o.columns * 0.4)
	vim.cmd("botright " .. width .. "vsplit")
	self.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(self.win, self.buf)
	vim.wo[self.win].number = false
	vim.wo[self.win].relativenumber = false
	vim.wo[self.win].signcolumn = "no"
	vim.wo[self.win].wrap = true
	vim.wo[self.win].linebreak = true

	vim.cmd("belowright 3split")
	self.input_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(self.input_win, self.input_buf)
	vim.wo[self.input_win].winfixheight = true
	vim.wo[self.input_win].number = false
	vim.wo[self.input_win].relativenumber = false
	vim.wo[self.input_win].signcolumn = "no"

	-- 输入框动态高度
	self:_setup_input_autoresize()

	-- 欢迎
	vim.bo[self.buf].modifiable = true
	vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, { "# 频道", "" })
	vim.bo[self.buf].modifiable = false

	-- keymaps
	vim.keymap.set({ "n", "i" }, "<CR>", function()
		self:_submit_input()
	end, { buffer = self.input_buf, noremap = true, silent = true })

	vim.keymap.set("n", "q", function()
		self:hide()
	end, { buffer = self.buf, noremap = true, silent = true })

	vim.keymap.set("n", "q", function()
		self:hide()
	end, { buffer = self.input_buf, noremap = true, silent = true })

	-- BufWipeout 保护
	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = self.buf,
		once = true,
		callback = function()
			channel:_cleanup_agents()
		end,
	})

	-- VimLeavePre
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = vim.api.nvim_create_augroup("acp_bus_cleanup", { clear = true }),
		once = true,
		callback = function()
			channel:save_snapshot()
			channel:_cleanup_agents()
		end,
	})

	-- 聚焦输入框
	if self.input_win and vim.api.nvim_win_is_valid(self.input_win) then
		vim.api.nvim_set_current_win(self.input_win)
		vim.cmd("startinsert")
	end

	self:_refresh_winbar()
end

--- 刷新频道窗口的 winbar
function ChannelView:_refresh_winbar()
	if not self.win or not vim.api.nvim_win_is_valid(self.win) then return end
	local channel = self.channel
	local win_width = vim.api.nvim_win_get_width(self.win)
	local parts = {}
	local names = {}
	for name in pairs(channel.agents) do
		names[#names + 1] = name
	end
	table.sort(names, function(a, b)
		if a == "main" then return true end
		if b == "main" then return false end
		return a < b
	end)
	local max_label = math.max(12, math.floor((win_width - 2) / math.max(1, #names)) - 3)
	max_label = math.min(max_label, 25)

	local queue_depth = channel.scheduler:main_queue_depth()

	for _, name in ipairs(names) do
		local agent = channel.agents[name]
		local icon, hl, hint
		local status = agent.status or "idle"
		if agent.client then
			if not agent.client.alive then
				status = "disconnected"
			elseif agent.streaming then
				status = "streaming"
			end
		elseif agent.kind ~= "local" and agent.status ~= "connecting" then
			status = "disconnected"
		end
		if status == "disconnected" or status == "error" then
			icon, hl = "○", "Comment"
		elseif status == "connecting" then
			icon, hl = "◌", "Comment"
		elseif status == "streaming" then
			icon, hl = "●", "DiagnosticOk"
			hint = truncate(agent.activity, 10)
		else
			icon, hl = "◉", "Normal"
		end
		-- RPC 通道健康检测：agent 在 streaming 状态超过 60s 且无 RPC 回调
		local rpc_warn = false
		if status == "streaming" and agent.kind ~= "local" and agent.prompt_start_time then
			local elapsed = os.time() - agent.prompt_start_time
			if elapsed >= 60 and not agent.last_rpc_time then
				rpc_warn = true -- 从未通过 RPC 回调
			elseif elapsed >= 60 and agent.last_rpc_time and agent.last_rpc_time < agent.prompt_start_time then
				rpc_warn = true -- 本轮 prompt 期间无 RPC 回调
			end
		end
		if rpc_warn then
			hl = "DiagnosticWarn"
		end

		local adapter = agent.adapter_name or "?"
		local base = name == adapter and name or (name .. "/" .. adapter)
		base = truncate(base, max_label - 4)
		local label = hint and string.format("%s %s [%s]", icon, base, hint) or (icon .. " " .. base)
		if rpc_warn then
			label = label .. " RPC?"
		end
		if name == "main" and queue_depth > 0 then
			label = label .. string.format(" [q:%d]", queue_depth)
		end
		parts[#parts + 1] = string.format("%%#%s#%s%%*", hl, label)
	end
	if #parts == 0 then
		vim.wo[self.win].winbar = " 频道"
	else
		vim.wo[self.win].winbar = " " .. table.concat(parts, "  ")
	end
end

--- 渲染单条消息到 buffer
function ChannelView:_render_message(msg, gap)
	if not self.buf or not vim.api.nvim_buf_is_valid(self.buf) then return end
	vim.bo[self.buf].modifiable = true
	local count = vim.api.nvim_buf_line_count(self.buf)

	local lines = {}
	if count > 2 then
		lines[#lines + 1] = ""
		lines[#lines + 1] = "---"
		lines[#lines + 1] = ""
	else
		lines[#lines + 1] = ""
	end

	lines[#lines + 1] = "## " .. msg.from
	lines[#lines + 1] = ""

	local meta = { os.date("%Y-%m-%d %H:%M:%S", msg.timestamp) }
	local gap_str = format_gap(gap)
	if gap_str then
		meta[#meta + 1] = gap_str
	end
	lines[#lines + 1] = "*" .. table.concat(meta, " · ") .. "*"
	lines[#lines + 1] = ""

	for _, line in ipairs(render_markdown_content(msg.content)) do
		lines[#lines + 1] = line
	end
	vim.api.nvim_buf_set_lines(self.buf, count, count, false, lines)
	vim.bo[self.buf].modifiable = false
	self:_scroll_to_bottom()
end

--- 滚动到底部
function ChannelView:_scroll_to_bottom()
	if self.win and vim.api.nvim_win_is_valid(self.win) then
		local count = vim.api.nvim_buf_line_count(self.buf)
		pcall(vim.api.nvim_win_set_cursor, self.win, { count, 0 })
	end
end

--- 输入框动态高度
function ChannelView:_setup_input_autoresize()
	if not self.input_buf then return end
	local group = vim.api.nvim_create_augroup("acp_bus_autoresize_" .. self.input_buf, { clear = true })
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = group,
		buffer = self.input_buf,
		callback = function()
			if not self.input_win or not vim.api.nvim_win_is_valid(self.input_win) then return end
			local line_count = vim.api.nvim_buf_line_count(self.input_buf)
			local height = math.max(3, math.min(10, line_count))
			vim.api.nvim_win_set_height(self.input_win, height)
		end,
	})
end

--- 提交输入
function ChannelView:_submit_input()
	local lines = vim.api.nvim_buf_get_lines(self.input_buf, 0, -1, false)
	local text = vim.trim(table.concat(lines, "\n"))
	if text == "" then return end
	vim.api.nvim_buf_set_lines(self.input_buf, 0, -1, false, { "" })

	-- / 命令拦截
	if text:match("^/") then
		local commands = require("acp.commands")
		if commands.handle_channel(self.channel, text, self) then
			return
		end
	end

	local has_mention = text:find("@[%w_%-]+")
	if not has_mention then
		text = "@main " .. text
	end
	self.channel:post("你", text)
end

--- 只关窗口
function ChannelView:hide()
	if self.input_win and vim.api.nvim_win_is_valid(self.input_win) then
		vim.api.nvim_win_close(self.input_win, true)
		self.input_win = nil
	end
	if self.win and vim.api.nvim_win_is_valid(self.win) then
		vim.api.nvim_win_close(self.win, true)
		self.win = nil
	end
end

--- 重新打开窗口
function ChannelView:show()
	if not self.buf or not vim.api.nvim_buf_is_valid(self.buf) then
		return false
	end
	local width = math.floor(vim.o.columns * 0.4)
	vim.cmd("botright " .. width .. "vsplit")
	self.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(self.win, self.buf)
	vim.wo[self.win].number = false
	vim.wo[self.win].relativenumber = false
	vim.wo[self.win].signcolumn = "no"
	vim.wo[self.win].wrap = true
	vim.wo[self.win].linebreak = true

	vim.api.nvim_set_current_win(self.win)
	vim.cmd("belowright 3split")
	self.input_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(self.input_win, self.input_buf)
	vim.wo[self.input_win].winfixheight = true
	vim.wo[self.input_win].number = false
	vim.wo[self.input_win].relativenumber = false
	vim.wo[self.input_win].signcolumn = "no"

	self:_refresh_winbar()
	self:_setup_input_autoresize()

	vim.api.nvim_set_current_win(self.input_win)
	vim.cmd("startinsert")
	return true
end

--- 关闭 UI
function ChannelView:close()
	if self.input_win and vim.api.nvim_win_is_valid(self.input_win) then
		vim.api.nvim_win_close(self.input_win, true)
	end
	if self.win and vim.api.nvim_win_is_valid(self.win) then
		vim.api.nvim_win_close(self.win, true)
	end
	if self.buf and vim.api.nvim_buf_is_valid(self.buf) then
		vim.api.nvim_buf_delete(self.buf, { force = true })
	end
	if self.input_buf and vim.api.nvim_buf_is_valid(self.input_buf) then
		vim.api.nvim_buf_delete(self.input_buf, { force = true })
	end
end

--- 打开指定 agent 的 Chat 窗口
function ChannelView:open_agent_buf(name)
	local agent = self.channel.agents[name]
	if not agent or not agent.chat then
		vim.notify("[acp] agent not found: " .. name, vim.log.levels.WARN)
		return
	end
	agent.chat:show()
end

return ChannelView
