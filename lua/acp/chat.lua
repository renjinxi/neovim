--- 私聊 Buffer：1v1 对话 UI（右侧 vsplit + 底部输入框）
local client_mod = require("acp.client")
local adapter_mod = require("acp.adapter")

local LOG_DIR = vim.fn.stdpath("config") .. "/logs"
local LOG_FILE = LOG_DIR .. "/acp-chat.log"

local function log(level, msg)
	vim.fn.mkdir(LOG_DIR, "p")
	local f = io.open(LOG_FILE, "a")
	if not f then return end
	f:write(string.format("%s [%s] chat: %s\n", os.date("%H:%M:%S"), level, msg))
	f:close()
end

local Chat = {}
Chat.__index = Chat

--- 创建新 chat 实例
--- @param adapter_name string "claude" | "gemini"
--- @param opts? table {api_num?, cwd?}
function Chat.new(adapter_name, opts)
	opts = opts or {}
	return setmetatable({
		adapter_name = adapter_name,
		opts = opts,
		client = nil,
		buf = nil, -- 主 buffer（消息展示）
		win = nil,
		input_buf = nil, -- 输入 buffer
		input_win = nil,
		streaming = false,
		stream_started = false, -- 当前 turn 是否已写 header
		on_ready = nil, -- client 启动成功后的回调
		display_name = opts.agent_name, -- 显示名（频道 agent 名）
		on_agent_update = nil, -- 频道回调：session/update 转发
		on_submit = nil, -- 频道回调：输入框提交走频道路由
		on_exit_notify = nil, -- 频道回调：进程退出通知
	}, Chat)
end

--- 打开 chat（创建 buffer + window + 启动 client）
function Chat:open()
	-- 主 buffer
	self.buf = vim.api.nvim_create_buf(false, true)
	vim.bo[self.buf].buftype = "nofile"
	vim.bo[self.buf].bufhidden = "hide"
	vim.bo[self.buf].swapfile = false
	vim.bo[self.buf].filetype = "markdown"
	local name = "acp://" .. self.adapter_name .. "/" .. os.time()
	pcall(vim.api.nvim_buf_set_name, self.buf, name)

	-- 输入 buffer
	self.input_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[self.input_buf].buftype = "nofile"
	vim.bo[self.input_buf].bufhidden = "hide"
	vim.bo[self.input_buf].swapfile = false

	-- 布局：右侧 vsplit
	local width = math.floor(vim.o.columns * 0.4)
	vim.cmd("botright " .. width .. "vsplit")
	self.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(self.win, self.buf)
	vim.wo[self.win].number = false
	vim.wo[self.win].relativenumber = false
	vim.wo[self.win].signcolumn = "no"
	vim.wo[self.win].wrap = true
	vim.wo[self.win].linebreak = true

	-- 底部输入框（动态高度，初始 3 行）
	vim.cmd("belowright 3split")
	self.input_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(self.input_win, self.input_buf)
	vim.wo[self.input_win].winfixheight = true
	vim.wo[self.input_win].number = false
	vim.wo[self.input_win].relativenumber = false
	vim.wo[self.input_win].signcolumn = "no"
	vim.wo[self.input_win].wrap = true

	-- 输入框动态高度
	self:_setup_input_autoresize()

	-- winbar 初始化
	self:_refresh_winbar()

	-- 欢迎信息
	vim.bo[self.buf].modifiable = true
	vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, {
		"# ACP Chat: " .. self.adapter_name,
		"",
		"连接中...",
	})
	vim.bo[self.buf].modifiable = false

	-- keymaps：输入框 <CR> 发送
	vim.keymap.set({ "n", "i" }, "<CR>", function()
		self:_submit_input()
	end, { buffer = self.input_buf, noremap = true, silent = true })

	-- keymaps：<C-c> 取消 streaming
	vim.keymap.set({ "n", "i" }, "<C-c>", function()
		self:cancel()
	end, { buffer = self.input_buf, noremap = true, silent = true })

	-- keymaps：q 只关窗口，不杀进程
	vim.keymap.set("n", "q", function()
		self:hide()
	end, { buffer = self.buf, noremap = true, silent = true })

	-- BufWipeout 保护
	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = self.buf,
		once = true,
		callback = function()
			if self.client then
				pcall(function() self.client:stop() end)
				self.client = nil
			end
		end,
	})

	-- VimLeavePre 清理
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = vim.api.nvim_create_augroup("acp_chat_cleanup_" .. self.buf, { clear = true }),
		once = true,
		callback = function()
			if self.client then
				pcall(function() self.client:stop() end)
			end
		end,
	})

	-- 先聚焦输入框，不等 client 连接（#37 修复启动期键盘不响应）
	if self.input_win and vim.api.nvim_win_is_valid(self.input_win) then
		vim.api.nvim_set_current_win(self.input_win)
		vim.cmd("startinsert")
	end

	-- 启动 client（异步，不阻塞 UI）
	vim.schedule(function()
		self:_start_client()
	end)
end

--- headless 启动：只创建 buffer + client，不创建窗口
function Chat:open_headless()
	log("INFO", "open_headless  adapter=" .. self.adapter_name
		.. "  agent=" .. tostring(self.display_name))
	local display_name = self.display_name or self.adapter_name

	-- 主 buffer
	self.buf = vim.api.nvim_create_buf(false, true)
	vim.bo[self.buf].buftype = "nofile"
	vim.bo[self.buf].bufhidden = "hide"
	vim.bo[self.buf].swapfile = false
	vim.bo[self.buf].filetype = "markdown"
	pcall(vim.api.nvim_buf_set_name, self.buf, "acp://agent/" .. display_name .. "/" .. os.time())

	-- 输入 buffer（show() 时需要）
	self.input_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[self.input_buf].buftype = "nofile"
	vim.bo[self.input_buf].bufhidden = "hide"
	vim.bo[self.input_buf].swapfile = false

	-- 欢迎
	vim.bo[self.buf].modifiable = true
	vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, {
		"# Agent: " .. display_name,
		"",
		"连接中...",
	})
	vim.bo[self.buf].modifiable = false

	-- keymaps（buffer-local，show() 后生效）
	vim.keymap.set({ "n", "i" }, "<CR>", function()
		self:_submit_input()
	end, { buffer = self.input_buf, noremap = true, silent = true })

	vim.keymap.set({ "n", "i" }, "<C-c>", function()
		self:cancel()
	end, { buffer = self.input_buf, noremap = true, silent = true })

	vim.keymap.set("n", "q", function()
		self:hide()
	end, { buffer = self.buf, noremap = true, silent = true })

	-- BufWipeout 保护
	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = self.buf,
		once = true,
		callback = function()
			if self.client then
				pcall(function() self.client:stop() end)
				self.client = nil
			end
		end,
	})

	-- VimLeavePre 清理
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = vim.api.nvim_create_augroup("acp_chat_cleanup_" .. self.buf, { clear = true }),
		once = true,
		callback = function()
			if self.client then
				pcall(function() self.client:stop() end)
			end
		end,
	})

	-- 启动 client
	vim.schedule(function()
		self:_start_client()
	end)
end

--- 启动 ACP client
function Chat:_start_client()
	log("INFO", "_start_client  adapter=" .. self.adapter_name
		.. "  agent=" .. tostring(self.display_name)
		.. "  cwd=" .. (self.opts.cwd or vim.fn.getcwd()))
	local adapter_config = adapter_mod.get(self.adapter_name, self.opts)
	self.client = client_mod.new(adapter_config)

	local ok, start_err = pcall(function()
		self.client:start({
			cwd = self.opts.cwd or vim.fn.getcwd(),
			on_update = function(params)
				self:_on_update(params)
			end,
			on_exit = function(code, _)
				vim.schedule(function()
					log("INFO", "on_exit  adapter=" .. self.adapter_name
						.. "  code=" .. tostring(code)
						.. "  agent=" .. tostring(self.display_name))
					self:_append_system("进程退出 (code=" .. tostring(code) .. ")")
					self:_refresh_winbar()
					-- 回调通知
					if self.on_exit_notify then
						self.on_exit_notify(code)
					end
				end)
			end,
		})
	end)

	local display_name = self.display_name or self.adapter_name
	local header = self.display_name and ("# Agent: " .. display_name) or ("# ACP Chat: " .. display_name)

	vim.bo[self.buf].modifiable = true
	if ok then
		log("INFO", "_start_client ok  adapter=" .. display_name)
		vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, {
			header,
			"",
			"已连接。在下方输入框输入消息，回车发送。",
			"",
		})
		self:_refresh_winbar()
		-- 聚焦到输入框
		if self.input_win and vim.api.nvim_win_is_valid(self.input_win) then
			vim.api.nvim_set_current_win(self.input_win)
			vim.cmd("startinsert")
		end
		-- 通知外部 client 已就绪
		log("INFO", "on_ready  adapter=" .. display_name
			.. "  session=" .. tostring(self.client and self.client.session_id))
		if self.on_ready then
			self.on_ready(self.client)
		end
	else
		log("ERROR", "_start_client FAILED  adapter=" .. display_name
			.. "  err=" .. tostring(start_err))
		vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, {
			header,
			"",
			"连接失败: " .. tostring(start_err),
		})
		self:_refresh_winbar()
	end
	vim.bo[self.buf].modifiable = false
end

--- 提交输入框内容
function Chat:_submit_input()
	if self.streaming then
		vim.notify("[acp] 等待回复中… <C-c> 取消", vim.log.levels.WARN)
		return
	end
	local lines = vim.api.nvim_buf_get_lines(self.input_buf, 0, -1, false)
	local text = vim.trim(table.concat(lines, "\n"))
	if text == "" then
		return
	end
	-- 清空输入框
	vim.api.nvim_buf_set_lines(self.input_buf, 0, -1, false, { "" })

	-- 频道回调：通过频道路由
	if self.on_submit then
		log("INFO", "_submit_input  channel_route  agent=" .. tostring(self.display_name)
			.. "  text_len=" .. #text)
		self.on_submit(text)
	else
		self:send(text)
	end
end

--- 发送消息
function Chat:send(text)
	-- 渲染 user 消息
	self:_append_role("You", text)
	self.streaming = true
	self.stream_started = false

	self:_refresh_winbar()
	self.client:prompt(text, function(stop_reason)
		vim.schedule(function()
			self.streaming = false
			self.stream_started = false
			self:_refresh_winbar()
			if stop_reason == "cancelled" then
				self:_append_system("(已取消)")
			end
			-- 聚焦回输入框
			if self.input_win and vim.api.nvim_win_is_valid(self.input_win) then
				vim.api.nvim_set_current_win(self.input_win)
				vim.cmd("startinsert")
			end
		end)
	end)
end

--- 处理 session/update notification
function Chat:_on_update(params)
	if not params or not params.update then
		return
	end
	local update = params.update
	local kind = update.sessionUpdate
	if not kind then
		return
	end

	if kind == "agent_message_chunk" then
		if update.content then
			self:_append_chunk(update.content)
		end
	elseif kind == "agent_thought_chunk" then
		-- M0: 跳过思考过程
	elseif kind == "tool_call" then
		local title = update.title or "tool"
		self:_append_system("🔧 " .. title)
	elseif kind == "tool_call_update" then
		local status = update.status
		if status == "completed" or status == "failed" then
			local title = update.title or "tool"
			self:_append_system("  → " .. title .. ": " .. status)
		end
	end

	-- 频道回调：转发 update
	if self.on_agent_update then
		self.on_agent_update(params)
	end
end

--- 追加流式 chunk 到 buffer
function Chat:_append_chunk(content)
	-- 对齐 codecompanion get_renderable_text
	local Client = require("acp.client").Client
	local text = Client.get_renderable_text(content)
	if not text or text == "" then
		return
	end

	vim.bo[self.buf].modifiable = true

	-- 首次 chunk：写 assistant header
	if not self.stream_started then
		self.stream_started = true
		local count = vim.api.nvim_buf_line_count(self.buf)
		vim.api.nvim_buf_set_lines(self.buf, count, count, false, { "", "## Assistant", "" })
	end

	-- 追加文本
	local last_idx = vim.api.nvim_buf_line_count(self.buf) - 1
	local last_line = vim.api.nvim_buf_get_lines(self.buf, last_idx, last_idx + 1, false)[1] or ""
	local parts = vim.split(text, "\n", { plain = true })
	parts[1] = last_line .. parts[1]
	vim.api.nvim_buf_set_lines(self.buf, last_idx, last_idx + 1, false, parts)

	vim.bo[self.buf].modifiable = false
	self:_scroll_to_bottom()
end

--- 追加角色消息（完整块）
function Chat:_append_role(role, text)
	vim.bo[self.buf].modifiable = true
	local count = vim.api.nvim_buf_line_count(self.buf)
	local lines = { "", "## " .. role, "" }
	for _, line in ipairs(vim.split(text, "\n", { plain = true })) do
		lines[#lines + 1] = line
	end
	vim.api.nvim_buf_set_lines(self.buf, count, count, false, lines)
	vim.bo[self.buf].modifiable = false
	self:_scroll_to_bottom()
end

--- 追加频道来源消息（区分于普通对话）
--- @param from string 发送者名字
--- @param text string 消息内容
function Chat:append_bus_message(from, text)
	vim.bo[self.buf].modifiable = true
	local count = vim.api.nvim_buf_line_count(self.buf)
	local lines = { "", "## 📨 频道 ← " .. from, "" }
	for _, line in ipairs(vim.split(text, "\n", { plain = true })) do
		lines[#lines + 1] = line
	end
	vim.api.nvim_buf_set_lines(self.buf, count, count, false, lines)
	vim.bo[self.buf].modifiable = false
	self:_scroll_to_bottom()
end

--- 追加系统消息（灰色小字）
function Chat:_append_system(text)
	vim.bo[self.buf].modifiable = true
	local count = vim.api.nvim_buf_line_count(self.buf)
	vim.api.nvim_buf_set_lines(self.buf, count, count, false, { "*" .. text .. "*" })
	vim.bo[self.buf].modifiable = false
	self:_scroll_to_bottom()
end

--- 滚动到底部
function Chat:_scroll_to_bottom()
	if self.win and vim.api.nvim_win_is_valid(self.win) then
		local count = vim.api.nvim_buf_line_count(self.buf)
		pcall(vim.api.nvim_win_set_cursor, self.win, { count, 0 })
	end
end

--- 取消当前 streaming
function Chat:cancel()
	if not self.streaming then return end
	if self.client then
		self.client:cancel()
	end
	self.streaming = false
	self.stream_started = false
	self:_append_system("(已取消)")
end

--- 刷新 winbar（agent 状态）
function Chat:_refresh_winbar()
	if not self.win or not vim.api.nvim_win_is_valid(self.win) then return end
	local icon, hl
	if not self.client or not self.client.alive then
		icon, hl = "○", "Comment"
	elseif self.streaming then
		icon, hl = "●", "DiagnosticOk"
	else
		icon, hl = "◉", "Normal"
	end
	local display = self.display_name or self.adapter_name
	local label = string.format("%s %s", icon, display)
	vim.wo[self.win].winbar = string.format(" %%#%s#%s%%*", hl, label)
end

--- 输入框动态高度（min 3, max 10）
function Chat:_setup_input_autoresize()
	if not self.input_buf then return end
	local group = vim.api.nvim_create_augroup("acp_chat_autoresize_" .. self.input_buf, { clear = true })
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

--- 只关窗口，保留进程
function Chat:hide()
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
function Chat:show()
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

	-- 先切到主 win，再 split 输入框，保证成对
	vim.api.nvim_set_current_win(self.win)
	vim.cmd("belowright 3split")
	self.input_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(self.input_win, self.input_buf)
	vim.wo[self.input_win].winfixheight = true
	vim.wo[self.input_win].number = false
	vim.wo[self.input_win].relativenumber = false
	vim.wo[self.input_win].signcolumn = "no"
	vim.wo[self.input_win].wrap = true

	self:_refresh_winbar()
	self:_setup_input_autoresize()

	vim.api.nvim_set_current_win(self.input_win)
	vim.cmd("startinsert")
	return true
end

--- 关闭 chat
function Chat:close()
	if self.client then
		self.client:stop()
		self.client = nil
	end
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

local M = {}
M.Chat = Chat

function M.new(adapter_name, opts)
	return Chat.new(adapter_name, opts)
end

return M
