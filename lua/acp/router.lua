--- @mention 路由逻辑
local LOG_DIR = vim.fn.stdpath("config") .. "/logs"
local LOG_FILE = LOG_DIR .. "/acp-bus.log"

local function log(level, msg)
	vim.fn.mkdir(LOG_DIR, "p")
	local f = io.open(LOG_FILE, "a")
	if not f then return end
	f:write(string.format("%s [%s] router: %s\n", os.date("%H:%M:%S"), level, msg))
	f:close()
end

local Router = {}
Router.__index = Router

--- @param bus table Bus 实例（提供 agents 和 scheduler 引用）
function Router.new(bus)
	return setmetatable({
		bus = bus,
		max_depth = 5,
	}, Router)
end

--- 解析 @mention，推送给被 @ 的 agent（跳过发送者自己）
--- @param content string 消息内容
--- @param from string 发送者名称
--- @param depth? number 路由深度（防循环）
function Router:route(content, from, depth)
	depth = depth or 0
	if depth >= self.max_depth then
		log("WARN", "route depth limit  from=" .. from)
		return
	end
	local mentioned = {}
	for name in content:gmatch("@([%w_%-]+)") do
		mentioned[name] = true
	end
	for name in pairs(mentioned) do
		if name ~= from and self.bus.agents[name] then
			log("DEBUG", "route  from=" .. from .. "  → " .. name)
			self:send_to(name, content, from)
		end
	end
end

--- 统一消息分发：根据 agent.kind 选择发送方式
function Router:send_to(name, content, from)
	local agent = self.bus.agents[name]
	if not agent then return end
	if agent.kind == "local" then
		self.bus.scheduler:push_to_main(content, from)
	else
		self.bus.scheduler:push_to_agent(name, content, from)
	end
end

return Router
