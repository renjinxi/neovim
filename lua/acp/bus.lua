--- 频道 Buffer：多 agent 消息展示（M0 简化版，单 agent）
local client_mod = require("acp.client")
local adapter_mod = require("acp.adapter")

local Bus = {}
Bus.__index = Bus

function Bus.new()
	return setmetatable({
		messages = {}, -- [{from, content, timestamp}]
		agents = {}, -- {name -> {client, streaming}}
		buf = nil,
		win = nil,
		input_buf = nil,
		input_win = nil,
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

	-- keymaps
	vim.keymap.set({ "n", "i" }, "<CR>", function()
		self:_submit_input()
	end, { buffer = self.input_buf, noremap = true, silent = true })

	vim.keymap.set("n", "q", function()
		self:close()
	end, { buffer = self.buf, noremap = true, silent = true })

	-- 聚焦输入框
	if self.input_win and vim.api.nvim_win_is_valid(self.input_win) then
		vim.api.nvim_set_current_win(self.input_win)
		vim.cmd("startinsert")
	end
end

--- 添加 agent 到频道
--- @param name string agent 名称
--- @param adapter_name string "claude" | "gemini"
--- @param opts? table {api_num?, cwd?}
function Bus:add_agent(name, adapter_name, opts)
	opts = opts or {}
	local adapter_config = adapter_mod.get(adapter_name, opts)
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
		self.agents[name] = { client = client, streaming = false, stream_buf = "" }
		self:post("系统", name .. " (" .. adapter_name .. ") 已上线")
	else
		self:post("系统", name .. " 启动失败: " .. tostring(start_err))
	end
end

--- 发消息到频道
function Bus:post(from, content)
	local msg = {
		from = from,
		content = content,
		timestamp = os.time(),
	}
	self.messages[#self.messages + 1] = msg
	self:_render_message(msg)
end

--- 推送消息给指定 agent
function Bus:send_to_agent(name, text)
	local agent = self.agents[name]
	if not agent or not agent.client or not agent.client.alive then
		self:post("系统", name .. " 不在线")
		return
	end
	agent.streaming = true
	agent.stream_buf = ""
	agent.client:prompt(text, function(stop_reason)
		vim.schedule(function()
			agent.streaming = false
			-- 把累积的流式内容作为一条完整消息发到频道
			if agent.stream_buf ~= "" then
				self:post(name, agent.stream_buf)
				agent.stream_buf = ""
			end
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

	-- 发到频道
	self:post("你", text)

	-- 解析 @mention，推送给对应 agent
	local mentioned = {}
	for mention in text:gmatch("@([%w_%-]+)") do
		mentioned[mention] = true
	end

	if next(mentioned) then
		for name in pairs(mentioned) do
			if self.agents[name] then
				self:send_to_agent(name, text)
			end
		end
	else
		-- 没有 @：M0 简化，推给第一个 agent
		for name in pairs(self.agents) do
			self:send_to_agent(name, text)
			break
		end
	end
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
		end
	elseif kind == "tool_call" then
		local title = update.title or "tool"
		self:post(name, "🔧 " .. title)
	elseif kind == "tool_call_update" then
		local status = update.status
		if status == "completed" or status == "failed" then
			local title = update.title or "tool"
			self:post(name, "  → " .. title .. ": " .. status)
		end
	end
end

--- 从 content 提取文本（对齐 codecompanion get_renderable_text）
function Bus:_extract_text(content)
	local Client = require("acp.client").Client
	return Client.get_renderable_text(content) or ""
end

--- 渲染单条消息到 buffer
function Bus:_render_message(msg)
	vim.bo[self.buf].modifiable = true
	local count = vim.api.nvim_buf_line_count(self.buf)
	local prefix = "[" .. msg.from .. "]"
	local lines = {}
	for _, line in ipairs(vim.split(msg.content, "\n", { plain = true })) do
		if #lines == 0 then
			lines[1] = prefix .. "  " .. line
		else
			lines[#lines + 1] = string.rep(" ", #prefix + 2) .. line
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

--- 关闭频道
function Bus:close()
	for _, agent in pairs(self.agents) do
		if agent.client then
			agent.client:stop()
		end
	end
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
