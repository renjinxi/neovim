local M = {}

function M.setup()
	local Terminal = require("toggleterm.terminal").Terminal
	local env = require("core.env")

	-- 构建 Claude Code 命令的辅助函数
	local function build_claude_cmd(api_num)
		local base_url = env.get("CLAUDE_API" .. api_num .. "_BASE_URL")
		local token = env.get("CLAUDE_API" .. api_num .. "_TOKEN")

		if base_url and token and base_url ~= "your_token_" .. api_num .. "_here" and token ~= "your_token_" .. api_num .. "_here" then
			return string.format("ANTHROPIC_BASE_URL=%s ANTHROPIC_AUTH_TOKEN=%s claude", base_url, token)
		else
			return "claude"  -- 回退到默认命令
		end
	end
	
	-- 专用终端使用 count >= 2，保留 count=1 给默认的 <c-\> 映射
	local ncdu = Terminal:new({ cmd = "ncdu --color dark", hidden = true, direction = "float", count = 2 })
	local htop = Terminal:new({ cmd = "htop", hidden = true, direction = "float", count = 3 })
	local ipython = Terminal:new({ cmd = "ipython", hidden = true, count = 4 })
	local lua = Terminal:new({ cmd = "lua", hidden = true, count = 5 })
	local cling = Terminal:new({ cmd = "cling", hidden = true, count = 6 })
	local new_term = Terminal:new({ cmd = "/bin/zsh", hidden = true, direction = "float", count = 7 })
	local tig = Terminal:new({ cmd = "tig", hidden = true, direction = "float", count = 8 })
	local new_tab_term = Terminal:new({ cmd = "/bin/zsh", hidden = true, direction = "tab", count = 9 })
	local newsboat = Terminal:new({ cmd = "newsboat", hidden = true, direction = "tab", count = 10 })
	local claude_code = Terminal:new({
		cmd = "claude",
		hidden = true,
		direction = "tab",  -- 改为新 tab
		count = 11,
		on_open = function(term)
			vim.opt_local.relativenumber = false
			vim.opt_local.number = false
		end,
	})
	local codex = Terminal:new({
		cmd = "codex",
		hidden = true,
		direction = "tab",
		count = 16,
		on_open = function(term)
			vim.opt_local.relativenumber = false
			vim.opt_local.number = false
		end,
	})
	local kimi_claude_code = Terminal:new({
		cmd = "ANTHROPIC_BASE_URL=https://api.moonshot.cn/anthropic/ ANTHROPIC_API_KEY=$(cat ~/work/password/kimi-cc) claude",
		hidden = true,
		direction = "tab",  -- 改为新 tab
		count = 12,
		on_open = function(term)
			vim.opt_local.relativenumber = false
			vim.opt_local.number = false
		end,
	})
	local qwen = Terminal:new({
		cmd = "qwen",
		hidden = true,
		direction = "vertical",
		size = math.floor(vim.o.columns * 0.4),
		count = 13,
		on_open = function(term)
			vim.opt_local.relativenumber = false
			vim.opt_local.number = false
		end,
	})
	local gemini = Terminal:new({
		cmd = "gemini",
		hidden = true,
		direction = "vertical",
		size = math.floor(vim.o.columns * 0.4),
		count = 14,
		on_open = function(term)
			vim.opt_local.relativenumber = false
			vim.opt_local.number = false
		end,
	})
	local cursor_agent = Terminal:new({
		cmd = "cursor-agent",
		hidden = true,
		direction = "vertical",
		size = math.floor(vim.o.columns * 0.4),
		count = 15,
		on_open = function(term)
			vim.opt_local.relativenumber = false
			vim.opt_local.number = false
		end,
	})
	local claude_code_1 = Terminal:new({
		cmd = build_claude_cmd(1),
		hidden = true,
		direction = "tab",
		count = 17,
		on_open = function(term)
			vim.opt_local.relativenumber = false
			vim.opt_local.number = false
		end,
	})
	local claude_code_2 = Terminal:new({
		cmd = build_claude_cmd(2),
		hidden = true,
		direction = "tab",
		count = 18,
		on_open = function(term)
			vim.opt_local.relativenumber = false
			vim.opt_local.number = false
		end,
	})

	local function ncdu_toggle()
		ncdu:toggle()
	end

	local function htop_toggle()
		htop:toggle()
	end

	local function ipython_toggle()
		ipython:toggle()
	end

	local function cling_toggle()
		cling:toggle()
	end

	local function lua_toggle()
		lua:toggle()
	end

	local function newterm_toggle()
		new_term:toggle()
	end

	local function newsboat_toggle()
		newsboat:toggle()
	end
	local function newterm()
		new_tab_term:toggle()
	end

	local function kimi_claude_code_toggle()
		kimi_claude_code:toggle()
	end
	local function claude_code_toggle()
		claude_code:toggle()
	end
	local function codex_toggle()
		codex:toggle()
	end
	local function qwen_toggle()
		qwen:toggle()
	end
	local function gemini_toggle()
		gemini:toggle()
	end
	local function cursor_agent_toggle()
		cursor_agent:toggle()
	end
	local function claude_code_1_toggle()
		claude_code_1:toggle()
	end
	local function claude_code_2_toggle()
		claude_code_2:toggle()
	end

	-- 动态创建新的 Claude Code 标签页
	local claude_instances = {}
	local next_claude_count = 20 -- 从 20 开始计数，避免与现有终端冲突

	local function create_new_claude_tab()
		local Terminal = require("toggleterm.terminal").Terminal
		local count = next_claude_count
		next_claude_count = next_claude_count + 1

		local new_claude = Terminal:new({
			cmd = "claude",
			hidden = true,
			direction = "tab",
			count = count,
			on_open = function(term)
				vim.opt_local.relativenumber = false
				vim.opt_local.number = false
			end,
		})

		-- 保存实例引用
		claude_instances[count] = new_claude

		-- 打开新的 Claude Code 标签页
		new_claude:toggle()
	end

	-- 创建带有指定 API 配置的新 Claude Code 标签页
	local function create_new_claude_tab_with_api(api_num)
		local Terminal = require("toggleterm.terminal").Terminal
		local count = next_claude_count
		next_claude_count = next_claude_count + 1

		local cmd = build_claude_cmd(api_num)
		local new_claude = Terminal:new({
			cmd = cmd,
			hidden = true,
			direction = "tab",
			count = count,
			on_open = function(term)
				vim.opt_local.relativenumber = false
				vim.opt_local.number = false
			end,
		})

		-- 保存实例引用
		claude_instances[count] = new_claude

		-- 打开新的 Claude Code 标签页
		new_claude:toggle()
	end

	local keymap = {
		{ "<leader>g", group = "Terminal", nowait = false, remap = false },
		{ "<leader>ga", lua_toggle, desc = "Lua", nowait = false, remap = false },
		{ "<leader>gc", claude_code_toggle, desc = "Claude Code", nowait = false, remap = false },
		{ "<leader>gc1", claude_code_1_toggle, desc = "Claude Code API 1", nowait = false, remap = false },
		{ "<leader>gc2", claude_code_2_toggle, desc = "Claude Code API 2", nowait = false, remap = false },
		{ "<leader>gcn", create_new_claude_tab, desc = "New Claude Code Tab", nowait = false, remap = false },
		{ "<leader>gcn1", function() create_new_claude_tab_with_api(1) end, desc = "New Claude Code Tab (API 1)", nowait = false, remap = false },
		{ "<leader>gcn2", function() create_new_claude_tab_with_api(2) end, desc = "New Claude Code Tab (API 2)", nowait = false, remap = false },
		{ "<leader>gd", codex_toggle, desc = "Codex", nowait = false, remap = false },
		{ "<leader>gg", cursor_agent_toggle, desc = "Cursor Agent", nowait = false, remap = false },
		{ "<leader>gh", htop_toggle, desc = "Htop", nowait = false, remap = false },
		{ "<leader>gi", ipython_toggle, desc = "IPython", nowait = false, remap = false },
		{ "<leader>gk", kimi_claude_code_toggle, desc = "Kimi Claude Code", nowait = false, remap = false },
		{ "<leader>gl", gemini_toggle, desc = "Newsboat", nowait = false, remap = false },
		{ "<leader>gn", newterm_toggle, desc = "New Term", nowait = false, remap = false },
		{ "<leader>gq", qwen_toggle, desc = "Newsboat", nowait = false, remap = false },
		{ "<leader>gr", newsboat_toggle, desc = "Newsboat", nowait = false, remap = false },
		{ "<leader>gt", newterm, desc = "New Tab Term", nowait = false, remap = false },
		{ "<leader>gu", ncdu_toggle, desc = "Ncdu", nowait = false, remap = false },
	}
	require("which-key").add(keymap)
end

return M
