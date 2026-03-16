--- 轻量任务模型：数据 + done/artifact 原语
local Task = {}
Task.__index = Task

--- @param opts table {title, owner, requester}
function Task.new(opts)
	return setmetatable({
		id = "t-" .. os.time() .. "-" .. math.random(1000),
		title = opts.title or "",
		owner = opts.owner,
		requester = opts.requester,
		status = "queued", -- queued|running|done|failed
		artifacts = {},
		created_at = os.time(),
		finished_at = nil,
	}, Task)
end

function Task:start()
	self.status = "running"
end

function Task:done(artifacts)
	self.status = "done"
	self.finished_at = os.time()
	self.artifacts = artifacts or {}
end

function Task:fail(reason)
	self.status = "failed"
	self.finished_at = os.time()
end

return Task
