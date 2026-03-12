--- 频道 Buffer：多 agent 消息展示
local client_mod = require("acp.client")
local adapter_mod = require("acp.adapter")

local LOG_DIR = vim.fn.stdpath("config") .. "/logs"
local LOG_FILE = LOG_DIR .. "/acp-bus.log"

local function log(level, msg)
	vim.fn.mkdir(LOG_DIR, "p")
	local f = io.open(LOG_FILE, "a")
	if not f then
		return
	end
	f:write(string.format("%s [%s] bus: %s\n", os.date("%H:%M:%S"), level, msg))
	f:close()
end

local Bus = {}
Bus.__index = Bus

function Bus.new()
	return setmetatable({
		messages = {}, -- [{from, content, timestamp}]
		agents = {}, -- {name -> {client, streaming}}
		main_client = nil, -- 主 agent client，子 agent 回复时推送
		buf = nil,
		win = nil,
		input_buf = nil,
		input_win = nil,
		_main_busy = false,
		_main_queue = {},
	}, Bus)
end

--- 打开频道 buffer
function Bus:open()
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

	-- 欢迎
	vim.bo[self.buf].modifiable = true
	vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, { "# 频道", "" })
	vim.bo[self.buf].modifiable = false

	-- keymaps：q 只关窗口，不杀进程
	vim.keymap.set({ "n", "i" }, "<CR>", function()
		self:_submit_input()
	end, { buffer = self.input_buf, noremap = true, silent = true })

	vim.keymap.set("n", "q", function()
		self:hide()
	end, { buffer = self.buf, noremap = true, silent = true })

	vim.keymap.set("n", "q", function()
		self:hide()
	end, { buffer = self.input_buf, noremap = true, silent = true })

	-- BufWipeout 保护：buffer 被强制关闭时清理进程
	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = self.buf,
		once = true,
		callback = function()
			self:_cleanup_agents()
		end,
	})

	-- VimLeavePre：nvim 退出时清理所有进程
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = vim.api.nvim_create_augroup("acp_bus_cleanup", { clear = true }),
		once = true,
		callback = function()
			self:_cleanup_agents()
		end,
	})

	-- 聚焦输入框
	if self.input_win and vim.api.nvim_win_is_valid(self.input_win) then
		vim.api.nvim_set_current_win(self.input_win)
		vim.cmd("startinsert")
	end
end

--- 只关窗口，保留进程（可以重新打开）
function Bus:hide()
	if self.input_win and vim.api.nvim_win_is_valid(self.input_win) then
		vim.api.nvim_win_close(self.input_win, true)
		self.input_win = nil
	end
	if self.win and vim.api.nvim_win_is_valid(self.win) then
		vim.api.nvim_win_close(self.win, true)
		self.win = nil
	end
end

--- 重新打开已有频道的窗口
function Bus:show()
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

	-- 必须先切到主 buffer 的 win，再 split 输入框，保证成对
	vim.api.nvim_set_current_win(self.win)
	vim.cmd("belowright 3split")
	self.input_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(self.input_win, self.input_buf)
	vim.wo[self.input_win].winfixheight = true
	vim.wo[self.input_win].number = false
	vim.wo[self.input_win].relativenumber = false
	vim.wo[self.input_win].signcolumn = "no"

	vim.api.nvim_set_current_win(self.input_win)
	vim.cmd("startinsert")
	return true
end

--- 清理所有 agent 进程（不关 buffer）
function Bus:_cleanup_agents()
	for _, agent in pairs(self.agents) do
		if agent.client then
			pcall(function() agent.client:stop() end)
		end
	end
end

--- 添加 agent 到频道
--- @param name string agent 名称
--- @param adapter_name string "claude" | "c1" | "c2" | "gemini"
--- @param opts? table {api_num?, cwd?}
function Bus:add_agent(name, adapter_name, opts)
	opts = opts or {}
	local adapter_config = adapter_mod.get(adapter_name, vim.tbl_extend("force", opts, {
		bus_mode = true,
		agent_name = name,
	}))
	local client = client_mod.new(adapter_config)

	local ok, start_err = pcall(function()
		client:start({
			cwd = opts.cwd or vim.fn.getcwd(),
			on_update = function(params)
				self:_on_agent_update(name, params)
			end,
			on_exit = function(code, _)
				vim.schedule(function()
					self:post("系统", name .. " 退出 (code=" .. tostring(code) .. ")")
				end)
			end,
		})
	end)

	if ok then
		local chat_buf = vim.api.nvim_create_buf(false, true)
		vim.bo[chat_buf].buftype = "nofile"
		vim.bo[chat_buf].bufhidden = "hide"
		vim.bo[chat_buf].swapfile = false
		vim.bo[chat_buf].filetype = "markdown"
		pcall(vim.api.nvim_buf_set_name, chat_buf, "acp://agent/" .. name)
		vim.bo[chat_buf].modifiable = true
		vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, { "# Agent: " .. name, "" })
		vim.bo[chat_buf].modifiable = false

		self.agents[name] = {
			client = client,
			streaming = false,
			stream_buf = "",
			stream_started = false,
			system_prompt = adapter_config.system_prompt,
			prompted = false,
			chat_buf = chat_buf,
		}
		self:post("系统", name .. " (" .. adapter_name .. ") 已上线")
	else
		self:post("系统", name .. " 启动失败: " .. tostring(start_err))
	end
end

--- 发消息到频道，并按 @mention 路由推送
--- @param from string 发送者
--- @param content string 消息内容
--- @param opts? table {no_route?: bool}
function Bus:post(from, content, opts)
	local msg = {
		from = from,
		content = content,
		timestamp = os.time(),
	}
	self.messages[#self.messages + 1] = msg
	self:_render_message(msg)
	if not (opts and opts.no_route) then
		self:_route(content, from)
	end
end

--- 解析 @mention，推送给被 @ 的 agent 或主 client（跳过发送者自己）
function Bus:_route(content, from)
	local mentioned = {}
	for name in content:gmatch("@([%w_%-]+)") do
		mentioned[name] = true
	end
	for name in pairs(mentioned) do
		if name == from then
			-- 跳过发送者自己
		elseif self.agents[name] then
			self:send_to_agent(name, content)
		elseif name == "main" then
			self:_push_to_main(content)
		end
	end
end

--- 推送消息给主 agent client，回复完成后 post 到频道（串行队列，防并发）
function Bus:_push_to_main(content)
	if not self.main_client then
		log("WARN", "_push_to_main: main_client is nil")
		return
	end
	if not self.main_client.alive then
		log("WARN", "_push_to_main: main_client not alive")
		return
	end

	-- 队列：如果正在处理，入队等待
	if self._main_busy then
		log("INFO", "_push_to_main: queued  msg=" .. content:sub(1, 80))
		self._main_queue[#self._main_queue + 1] = content
		return
	end
	self._main_busy = true

	local t0 = os.clock()
	log("INFO", "_push_to_main: start  msg=" .. content:sub(1, 80))

	local stream_buf = ""
	local orig_on_update = self.main_client.on_update

	self.main_client.on_update = function(params)
		if orig_on_update then orig_on_update(params) end
		if not params or not params.update then return end
		local kind = params.update.sessionUpdate
		if kind == "agent_message_chunk" then
			local text = self:_extract_text(params.update.content)
			if text ~= "" then stream_buf = stream_buf .. text end
		end
	end

	self.main_client:prompt(content, function(_)
		self.main_client.on_update = orig_on_update
		local elapsed = math.floor((os.clock() - t0) * 1000)
		log("INFO", "_push_to_main: done  elapsed=" .. elapsed .. "ms  reply_len=" .. #stream_buf)
		if stream_buf ~= "" then
			vim.schedule(function()
				self:post("main", stream_buf)
			end)
		end
		-- 处理队列里的下一条
		self._main_busy = false
		if #self._main_queue > 0 then
			local next_msg = table.remove(self._main_queue, 1)
			vim.schedule(function()
				self:_push_to_main(next_msg)
			end)
		end
	end)
end

--- 推送消息给指定 agent
function Bus:send_to_agent(name, text)
	local agent = self.agents[name]
	if not agent or not agent.client or not agent.client.alive then
		self:post("系统", name .. " 不在线")
		return
	end
	-- 第一次发消息时，把 system prompt 前置
	local payload = text
	if not agent.prompted and agent.system_prompt then
		payload = agent.system_prompt .. "\n\n" .. text
		agent.prompted = true
	end
	agent.streaming = true
	agent.stream_buf = ""
	agent.stream_started = false
	-- 把 user 消息写入 agent chat_buf（完整格式）
	self:_append_agent_role(agent, "You", text)
	agent.client:prompt(payload, function(stop_reason)
		vim.schedule(function()
			agent.streaming = false
			agent.stream_started = false
			agent.stream_buf = ""
			if stop_reason == "cancelled" then
				self:post("系统", name .. " 已取消")
			end
		end)
	end)
end

--- 提交输入
function Bus:_submit_input()
	local lines = vim.api.nvim_buf_get_lines(self.input_buf, 0, -1, false)
	local text = vim.trim(table.concat(lines, "\n"))
	if text == "" then
		return
	end
	vim.api.nvim_buf_set_lines(self.input_buf, 0, -1, false, { "" })
	-- 没有 @mention 时默认推给 main
	local has_mention = text:find("@[%w_%-]+")
	if not has_mention then
		text = "@main " .. text
	end
	self:post("你", text)
end

--- 处理 agent 的 session/update
function Bus:_on_agent_update(name, params)
	if not params or not params.update then
		return
	end
	local update = params.update
	local kind = update.sessionUpdate
	if not kind then
		return
	end

	local agent = self.agents[name]
	if not agent then
		return
	end

	if kind == "agent_message_chunk" then
		local text = self:_extract_text(update.content)
		if text ~= "" then
			agent.stream_buf = (agent.stream_buf or "") .. text
			self:_append_agent_chunk(agent, text)
		end
	elseif kind == "tool_call" then
		local title = update.title or "tool"
		log("DEBUG", name .. " tool_call: " .. title)
		self:_append_agent_system(agent, "🔧 " .. title)
	elseif kind == "tool_call_update" then
		local status = update.status or ""
		local title = update.title or "tool"
		log("DEBUG", name .. " tool_update: " .. title .. " " .. status)
		if status == "completed" or status == "failed" then
			self:_append_agent_system(agent, "  → " .. title .. ": " .. status)
		end
	else
		log("DEBUG", name .. " update: " .. kind)
	end
end

--- 追加角色消息到 agent chat_buf（完整块）
function Bus:_append_agent_role(agent, role, text)
	local buf = agent.chat_buf
	if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
	vim.schedule(function()
		vim.bo[buf].modifiable = true
		local count = vim.api.nvim_buf_line_count(buf)
		local lines = { "", "## " .. role, "" }
		for _, line in ipairs(vim.split(text, "\n", { plain = true })) do
			lines[#lines + 1] = line
		end
		vim.api.nvim_buf_set_lines(buf, count, count, false, lines)
		vim.bo[buf].modifiable = false
	end)
end

--- 追加流式 chunk 到 agent chat_buf
function Bus:_append_agent_chunk(agent, text)
	local buf = agent.chat_buf
	if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
	vim.schedule(function()
		vim.bo[buf].modifiable = true
		if not agent.stream_started then
			agent.stream_started = true
			local count = vim.api.nvim_buf_line_count(buf)
			vim.api.nvim_buf_set_lines(buf, count, count, false, { "", "## Assistant", "" })
		end
		local last_idx = vim.api.nvim_buf_line_count(buf) - 1
		local last_line = vim.api.nvim_buf_get_lines(buf, last_idx, last_idx + 1, false)[1] or ""
		local parts = vim.split(text, "\n", { plain = true })
		parts[1] = last_line .. parts[1]
		vim.api.nvim_buf_set_lines(buf, last_idx, last_idx + 1, false, parts)
		vim.bo[buf].modifiable = false
	end)
end

--- 追加系统消息到 agent chat_buf
function Bus:_append_agent_system(agent, text)
	local buf = agent.chat_buf
	if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
	vim.schedule(function()
		vim.bo[buf].modifiable = true
		local count = vim.api.nvim_buf_line_count(buf)
		vim.api.nvim_buf_set_lines(buf, count, count, false, { "*" .. text .. "*" })
		vim.bo[buf].modifiable = false
	end)
end

--- 从 content 提取文本（对齐 codecompanion get_renderable_text）
function Bus:_extract_text(content)
	local Client = require("acp.client").Client
	return Client.get_renderable_text(content) or ""
end


--- 渲染单条消息到 buffer（带时间戳和间隔）
function Bus:_render_message(msg)
	if not self.buf or not vim.api.nvim_buf_is_valid(self.buf) then
		return
	end
	vim.bo[self.buf].modifiable = true
	local count = vim.api.nvim_buf_line_count(self.buf)

	-- 计算与上条消息的时间间隔
	local time_str = os.date("%H:%M:%S", msg.timestamp)
	local gap_str = ""
	if self._last_msg_time then
		local gap = msg.timestamp - self._last_msg_time
		if gap >= 60 then
			gap_str = string.format(" (+%dm%ds)", math.floor(gap / 60), gap % 60)
		elseif gap >= 2 then
			gap_str = string.format(" (+%ds)", gap)
		end
	end
	self._last_msg_time = msg.timestamp

	local prefix = "[" .. msg.from .. "]"
	local time_prefix = time_str .. gap_str .. "  "
	local indent = string.rep(" ", #time_prefix + #prefix + 2)
	local lines = {}
	for _, line in ipairs(vim.split(msg.content, "\n", { plain = true })) do
		if #lines == 0 then
			lines[1] = time_prefix .. prefix .. "  " .. line
		else
			lines[#lines + 1] = indent .. line
		end
	end
	vim.api.nvim_buf_set_lines(self.buf, count, count, false, lines)
	vim.bo[self.buf].modifiable = false
	self:_scroll_to_bottom()
end

--- 滚动到底部
function Bus:_scroll_to_bottom()
	if self.win and vim.api.nvim_win_is_valid(self.win) then
		local count = vim.api.nvim_buf_line_count(self.buf)
		pcall(vim.api.nvim_win_set_cursor, self.win, { count, 0 })
	end
end

--- 在右侧 vsplit 打开指定 agent 的 chat buffer
function Bus:open_agent_buf(name)
	local agent = self.agents[name]
	if not agent or not vim.api.nvim_buf_is_valid(agent.chat_buf) then
		vim.notify("[acp] agent not found: " .. name, vim.log.levels.WARN)
		return
	end
	local width = math.floor(vim.o.columns * 0.4)
	vim.cmd("botright " .. width .. "vsplit")
	vim.api.nvim_win_set_buf(0, agent.chat_buf)
	local win = vim.api.nvim_get_current_win()
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].wrap = true
	vim.wo[win].linebreak = true
	-- 滚到底部
	local count = vim.api.nvim_buf_line_count(agent.chat_buf)
	pcall(vim.api.nvim_win_set_cursor, win, { count, 0 })
	-- q 关窗
	vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = agent.chat_buf, noremap = true, silent = true })
end
--- @param last_n? number 默认 20
--- @return table[] [{from, content, timestamp}]
function Bus:read(last_n)
	last_n = last_n or 20
	local total = #self.messages
	local start = math.max(1, total - last_n + 1)
	local result = {}
	for i = start, total do
		result[#result + 1] = self.messages[i]
	end
	return result
end

--- 列出所有 agent 状态
--- @return table[] [{name, alive, streaming}]
function Bus:list_agents()
	local result = {}
	for name, agent in pairs(self.agents) do
		result[#result + 1] = {
			name = name,
			alive = agent.client and agent.client.alive or false,
			streaming = agent.streaming or false,
		}
	end
	return result
end

--- 关闭频道
function Bus:close()
	self:_cleanup_agents()
	self.agents = {}
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
M.Bus = Bus

function M.new()
	return Bus.new()
end

return M
