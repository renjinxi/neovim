local M = {}

local function format_value(value)
	if value == nil or value == vim.NIL or value == "" then
		return "-"
	end
	return tostring(value)
end

local function get_entries()
	local registry = require("acp.registry").get()
	local bus = registry:get_active_channel()
	if not bus then
		return nil, "没有活跃频道"
	end

	local entries = {}
	for name, agent in pairs(bus.agents or {}) do
		local session_id = agent.client and agent.client.session_id or nil
		local chat = agent.chat
		if not chat and agent.kind == "local" and bus.find_main_chat then
			chat = bus:find_main_chat()
		end
		entries[#entries + 1] = {
			name = name,
			adapter = agent.adapter_name or "-",
			status = agent.status or "idle",
			session_id = session_id,
			agent = agent,
			chat = chat,
		}
	end

	table.sort(entries, function(a, b)
		if a.name == "main" then
			return true
		end
		if b.name == "main" then
			return false
		end
		return a.name < b.name
	end)

	return entries, nil, bus
end

function M.open()
	local ok, pickers = pcall(require, "telescope.pickers")
	if not ok then
		vim.notify("[acp] telescope 未加载", vim.log.levels.WARN)
		return
	end

	local entries, err = get_entries()
	if not entries then
		vim.notify("[acp] " .. err, vim.log.levels.WARN)
		return
	end
	if #entries == 0 then
		vim.notify("[acp] 当前频道没有 agent", vim.log.levels.INFO)
		return
	end

	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	pickers.new({}, {
		prompt_title = "ACP Agents",
		finder = finders.new_table({
			results = entries,
			entry_maker = function(entry)
				local display = string.format(
					"%s | %s | %s | %s",
					entry.name,
					entry.adapter,
					entry.status,
					format_value(entry.session_id)
				)
				local ordinal = table.concat({
					entry.name,
					entry.adapter,
					entry.status,
					format_value(entry.session_id),
				}, " ")
				return {
					value = entry,
					display = display,
					ordinal = ordinal,
				}
			end,
		}),
		sorter = conf.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, map)
			local function current_entry()
				local selected = action_state.get_selected_entry()
				return selected and selected.value or nil
			end

			actions.select_default:replace(function()
				local entry = current_entry()
				actions.close(prompt_bufnr)
				if not entry then
					return
				end
				if entry.chat then
					entry.chat:show()
					return
				end
				vim.notify("[acp] agent chat 不可用: " .. entry.name, vim.log.levels.WARN)
			end)

			map({ "i", "n" }, "<C-o>", function()
				local entry = current_entry()
				actions.close(prompt_bufnr)
				if entry then
					require("acp").open_native_cli(entry.name)
				end
			end)

			return true
		end,
	}):find()
end

return M
