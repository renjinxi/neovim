--- JSON-RPC 2.0 工具库：LineBuffer + 编解码 + ID 生成
--- 对齐 codecompanion/utils/jsonrpc.lua 实现
local M = {}

-- 标准 JSON-RPC 错误码
M.errors = {
	PARSE = -32700,
	INVALID_REQUEST = -32600,
	METHOD_NOT_FOUND = -32601,
	INVALID_PARAMS = -32602,
	INTERNAL = -32603,
}

-- 空 params 必须编码为 {} 而不是 []
local function normalize_params(params)
	if not params then
		return vim.empty_dict()
	end
	if vim.tbl_isempty(params) then
		return vim.empty_dict()
	end
	return params
end

-- LineBuffer：处理 stdin 不完整行，按 \n 分割
local LineBuffer = {}
LineBuffer.__index = LineBuffer

function LineBuffer.new()
	return setmetatable({ _buf = "" }, LineBuffer)
end

function LineBuffer:feed(chunk)
	if not chunk or chunk == "" then
		return {}
	end
	self._buf = self._buf .. chunk
	local lines = {}
	while true do
		local pos = self._buf:find("\n", 1, true)
		if not pos then
			break
		end
		local line = self._buf:sub(1, pos - 1):gsub("\r$", "")
		self._buf = self._buf:sub(pos + 1)
		if line ~= "" then
			lines[#lines + 1] = line
		end
	end
	return lines
end

function LineBuffer:reset()
	self._buf = ""
end

M.LineBuffer = LineBuffer

function M.line_buffer()
	return LineBuffer.new()
end

-- ID 生成器
local _next_id = 0
function M.next_id()
	_next_id = _next_id + 1
	return _next_id
end

-- 编码
function M.encode_request(id, method, params)
	return vim.json.encode({ jsonrpc = "2.0", id = id, method = method, params = normalize_params(params) })
end

function M.encode_response(id, result)
	return vim.json.encode({ jsonrpc = "2.0", id = id, result = result or vim.empty_dict() })
end

function M.encode_error(id, code, message)
	return vim.json.encode({ jsonrpc = "2.0", id = id, error = { code = code, message = message } })
end

function M.encode_notification(method, params)
	return vim.json.encode({ jsonrpc = "2.0", method = method, params = normalize_params(params) })
end

-- 解码（对齐 codecompanion：跳过非 JSON 行）
function M.decode(line)
	if not line or not line:match("^%s*{") then
		return nil, "not json"
	end
	local ok, msg = pcall(vim.json.decode, line)
	if not ok then
		return nil, "json decode failed: " .. tostring(msg)
	end
	if type(msg) ~= "table" then
		return nil, "decoded value is not a table"
	end
	return msg
end

-- 类型判断
function M.is_request(msg)
	return msg.method ~= nil and msg.id ~= nil
end

function M.is_response(msg)
	return msg.id ~= nil and (msg.result ~= nil or msg.error ~= nil)
end

function M.is_notification(msg)
	return msg.method ~= nil and msg.id == nil
end

return M
