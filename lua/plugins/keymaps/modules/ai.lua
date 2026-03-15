local M = {}

function M.setup(opts)
	local api = {}
	local ai_float_profiles = {
		[1] = { provider = "claude", api = "1" },
		[2] = { provider = "claude", api = "2" },
		[3] = { provider = "claude", label = "workbench" },
		[4] = { provider = "gemini" },
		[5] = { provider = "claude", cwd = "~/.config/nvim", label = "nvim" },
		[6] = { provider = "claude", cwd = "~/.config/kitty", label = "kitty" },
	}

	local ai_providers = {
		claude = {
			supports_auto_accept = true,
			build = function(api_num, auto_accept)
				local env_mod = require("core.env")
				local flags = auto_accept and " --dangerously-skip-permissions --permission-mode acceptEdits" or ""
				local cmd = "claude" .. flags
				local env = nil
				local proxy = env_mod.get("CLAUDE_PROXY")
				if proxy and proxy ~= "" then
					env = {
						http_proxy = proxy,
						https_proxy = proxy,
						HTTP_PROXY = proxy,
						HTTPS_PROXY = proxy,
						all_proxy = proxy,
					}
				end
				if api_num then
					local n = tonumber(api_num)
					local base_url = env_mod.get("CLAUDE_API" .. n .. "_BASE_URL")
					local token = env_mod.get("CLAUDE_API" .. n .. "_TOKEN")
					if base_url and token then
						env = env or {}
						env.ANTHROPIC_BASE_URL = base_url
						env.ANTHROPIC_AUTH_TOKEN = token
					end
				end
				return { cmd = cmd, env = env }
			end,
			apis = { "1", "2" },
			default_api = nil,
			default_mode = "vsplit",
		},
		gemini = {
			supports_auto_accept = true,
			build = function(_, auto_accept)
				return { cmd = "gemini" .. (auto_accept and " --yolo" or "") }
			end,
			default_mode = "vsplit",
		},
		codex = {
			supports_auto_accept = true,
			build = function(_, auto_accept)
				return { cmd = "codex" .. (auto_accept and " --dangerously-bypass-approvals-and-sandbox" or "") }
			end,
			default_mode = "vsplit",
		},
		kimi = {
			build = function()
				return {
					cmd = "claude",
					env = {
						ANTHROPIC_BASE_URL = "https://api.moonshot.cn/anthropic/",
						ANTHROPIC_API_KEY = vim.fn.trim(vim.fn.system("cat ~/work/password/kimi-cc")),
					},
				}
			end,
			default_mode = "vsplit",
		},
		qwen = { build = function() return { cmd = "qwen" } end, default_mode = "vsplit" },
		cursor = { build = function() return { cmd = "cursor-agent" } end, default_mode = "vsplit" },
	}

	local provider_aliases = {
		c = "claude", g = "gemini", d = "codex",
		k = "kimi", q = "qwen", a = "cursor",
	}

	local mode_aliases = {
		t = "tab", f = "float", v = "vsplit", h = "hsplit", s = "half",
	}

	local function provider_display_name(provider)
		return (provider or "ai"):gsub("^%l", string.upper)
	end

	local function build_ai_command(provider, effective_api, auto_accept)
		local p = ai_providers[provider]
		if not p then
			return nil
		end
		if p.build then
			return p.build(effective_api, auto_accept)
		end
		return type(p.cmd) == "function" and { cmd = p.cmd(effective_api, auto_accept) } or { cmd = p.cmd }
	end

	local function build_ai_label(provider, effective_api, suffix)
		local label = provider_display_name(provider)
		if effective_api then
			label = label .. " [" .. effective_api .. "]"
		end
		if suffix and suffix ~= "" then
			label = label .. " [" .. suffix .. "]"
		end
		return " " .. label .. " "
	end

	local function parse_ai_arg(input)
		if ai_providers[input] then
			return input, nil, nil, false
		end
		local auto_accept = input:sub(-1) == "!"
		local s = auto_accept and input:sub(1, -2) or input
		local alias, api_str, mode_char = s:match("^(%a)(%d?)(%a?)$")
		if not alias then
			return input, nil, nil, false
		end
		local provider = provider_aliases[alias]
		if not provider then
			return input, nil, nil, false
		end
		local api_num = api_str ~= "" and api_str or nil
		local mode = mode_char ~= "" and mode_aliases[mode_char] or nil
		return provider, api_num, mode, auto_accept
	end

	local function supports_auto_accept(name)
		return ai_providers[name] and ai_providers[name].supports_auto_accept == true
	end

	api.ai_completions = (function()
		local list = {}
		for alias, name in pairs(provider_aliases) do
			table.insert(list, alias)
			local p = ai_providers[name]
			local has_bang = supports_auto_accept(name)
			if p.apis then
				for _, n in ipairs(p.apis) do
					table.insert(list, alias .. n)
					if has_bang then
						table.insert(list, alias .. n .. "!")
					end
				end
			end
			if has_bang then
				table.insert(list, alias .. "!")
			end
		end
		for name in pairs(ai_providers) do
			table.insert(list, name)
		end
		table.sort(list)
		return list
	end)()

	local function ai_launch(provider, effective_api, display_mode, auto_accept)
		local name = "ai_" .. provider .. "_" .. os.time() .. "_" .. math.random(1000)
		local cmd = build_ai_command(provider, effective_api, auto_accept)
		local label = build_ai_label(provider, effective_api)

		if display_mode == "half" then
			local width = math.floor(vim.o.columns * 0.5)
			opts.create_float_term(name, cmd, {
				width = width,
				height = vim.o.lines - 4,
				row = 1,
				col = vim.o.columns - width - 1,
				title = label,
			})
		elseif display_mode == "float" then
			opts.create_float_term(name, cmd, {
				width = 60,
				height = 16,
				row = 1,
				col = vim.o.columns - 60 - 1,
				title = label,
			})
		elseif display_mode == "vsplit" then
			opts.create_vertical_term(name, cmd, { width = math.floor(vim.o.columns * 0.4) })
		elseif display_mode == "hsplit" then
			opts.create_horizontal_term(name, cmd, { height = math.floor(vim.o.lines * 0.4) })
		else
			opts.create_tab_term(name, cmd)
		end
	end

	function api.terminal_gemini_toggle()
		opts.toggle_term("gemini", build_ai_command("gemini"), "vertical")
	end

	function api.terminal_cursor_agent_toggle()
		opts.toggle_term("cursor", build_ai_command("cursor"), "vertical")
	end

	function api.terminal_kimi_claude_code_toggle()
		opts.toggle_term("kimi", build_ai_command("kimi"), "tab")
	end

	function api.tab_terminal_claude(api_num)
		opts.toggle_term("claude_" .. (api_num or "default"), build_ai_command("claude", api_num and tostring(api_num) or nil), "tab")
	end

	function api.tab_terminal_claude_new(api_num)
		opts.create_tab_term("claude_new_" .. os.time(), build_ai_command("claude", api_num and tostring(api_num) or nil))
	end

	function api.tab_terminal_codex()
		opts.toggle_term("codex", build_ai_command("codex"), "tab")
	end

	function api.claude_vsplit(api_num)
		opts.toggle_term("claude_vsplit_" .. (api_num or "default"), build_ai_command("claude", api_num and tostring(api_num) or nil), "vertical", {
			width = math.floor(vim.o.columns * 0.4),
		})
	end

	function api.claude_hsplit(api_num)
		opts.toggle_term("claude_hsplit_" .. (api_num or "default"), build_ai_command("claude", api_num and tostring(api_num) or nil), "horizontal", {
			height = math.floor(vim.o.lines * 0.4),
		})
	end

	function api.claude_float(api_num)
		opts.toggle_term("claude_float_" .. (api_num or "default"), build_ai_command("claude", api_num and tostring(api_num) or nil), "float", {
			width = math.floor(vim.o.columns * 0.8),
			height = math.floor(vim.o.lines * 0.8),
			title = " Claude " .. (api_num and "[API " .. api_num .. "]" or "") .. " ",
		})
	end

	function api.claude_launcher()
		vim.ui.select({ "API 1", "API 2", "Default" }, { prompt = "选择 Claude API:" }, function(api_choice)
			if not api_choice then
				return
			end
			local api_num = api_choice == "API 1" and 1 or (api_choice == "API 2" and 2 or nil)
			vim.ui.select({ "新 Tab", "浮动窗口 (大)", "半屏 (右侧)", "水平分割", "垂直分割" }, { prompt = "选择显示方式:" }, function(display_choice)
				if not display_choice then
					return
				end

				local cmd = build_ai_command("claude", api_num and tostring(api_num) or nil)
				if display_choice == "新 Tab" then
					opts.create_tab_term("claude_new_" .. os.time(), cmd)
				elseif display_choice == "浮动窗口 (大)" then
					opts.create_float_term("claude_float_temp_" .. os.time(), cmd, {
						width = math.floor(vim.o.columns * 0.8),
						height = math.floor(vim.o.lines * 0.8),
						title = " Claude [" .. (api_choice or "Default") .. "] ",
					})
				elseif display_choice == "半屏 (右侧)" then
					local tabpage = vim.api.nvim_get_current_tabpage()
					local key = string.format("tab_%d_claude_half", tabpage)
					local width = math.floor(vim.o.columns * 0.5)
					local cfg = {
						width = width,
						height = vim.o.lines - 4,
						row = 1,
						col = vim.o.columns - width - 1,
						title = " Claude [T" .. vim.api.nvim_tabpage_get_number(tabpage) .. "] ",
					}
					local state = opts.float_terminals[key]
					if not state or not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
						opts.create_float_terminal(key, function()
							return cmd
						end, cfg)
					else
						opts.reopen_float_window(key, cfg)
					end
				elseif display_choice == "水平分割" then
					opts.create_horizontal_term("claude_hsplit_" .. os.time(), cmd, { height = math.floor(vim.o.lines * 0.4) })
				elseif display_choice == "垂直分割" then
					opts.create_vertical_term("claude_vsplit_" .. os.time(), cmd, { width = math.floor(vim.o.columns * 0.4) })
				end
			end)
		end)
	end

	function api.ai_open(input)
		local provider, api_num, mode, auto_accept = parse_ai_arg(input)
		local p = ai_providers[provider]
		if not p then
			vim.notify("Unknown: " .. input .. "\n用法: :AI <别名>[api][模式][!]\n别名: c g d k q a  模式: t f v h s  !: 自动接受", vim.log.levels.ERROR)
			return
		end
		ai_launch(provider, api_num or p.default_api, mode or p.default_mode, auto_accept)
	end

	function api.ai_set(input)
		local provider, api_num, mode = parse_ai_arg(input)
		local resolved = ai_providers[provider] and provider or (provider_aliases[provider] or provider)
		local p = ai_providers[resolved]
		if not p then
			vim.notify("Unknown: " .. input, vim.log.levels.ERROR)
			return
		end
		if api_num then
			p.default_api = api_num
			vim.notify(resolved .. " default api → " .. api_num)
		elseif mode then
			p.default_mode = mode
			vim.notify(resolved .. " default mode → " .. mode)
		else
			p.default_api = nil
			vim.notify(resolved .. " default api → cleared")
		end
	end

	function api.ai_status()
		local provider_lines = {}
		local profile_lines = {}
		local alias_map = {}
		for a, n in pairs(provider_aliases) do
			alias_map[n] = a
		end
		for name, p in pairs(ai_providers) do
			local a = alias_map[name] or "?"
			local api_str = p.default_api and (" api=" .. p.default_api) or ""
			local apis_str = p.apis and (" [" .. table.concat(p.apis, ",") .. "]") or ""
			table.insert(provider_lines, string.format("  %s %-8s %s%s%s", a, name, p.default_mode, api_str, apis_str))
		end
		for id, profile in pairs(ai_float_profiles) do
			local suffix = profile.label and (" [" .. profile.label .. "]") or ""
			local api_str = profile.api and (" api=" .. profile.api) or ""
			local cwd_str = profile.cwd and (" cwd=" .. vim.fn.fnamemodify(vim.fn.expand(profile.cwd), ":~")) or ""
			table.insert(profile_lines, string.format("  %d %-8s%s%s%s", id, profile.provider or "?", suffix, api_str, cwd_str))
		end
		table.sort(provider_lines)
		table.sort(profile_lines)
		vim.notify(
			"AI Providers:\n" .. table.concat(provider_lines, "\n") ..
			"\n\nAI Float Profiles:\n" .. table.concat(profile_lines, "\n") ..
			"\n\n:AI <别名>[api][模式]  :AISet <别名>[api|模式]"
		)
	end

	return {
		api = api,
		ai_float_profiles = ai_float_profiles,
		build_ai_command = build_ai_command,
		build_ai_label = build_ai_label,
	}
end

return M
