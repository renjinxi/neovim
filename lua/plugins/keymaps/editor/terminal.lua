local M = {}

function M.setup()
	local Terminal = require("toggleterm.terminal").Terminal
	local ncdu = Terminal:new({ cmd = "ncdu --color dark", hidden = true, direction = "float" })
	local htop = Terminal:new({ cmd = "htop", hidden = true, direction = "float" })
	local ipython = Terminal:new({ cmd = "ipython", hidden = true })
	local lua = Terminal:new({ cmd = "lua", hidden = true })
	local cling = Terminal:new({ cmd = "cling", hidden = true })
	local new_term = Terminal:new({ cmd = "/bin/zsh", hidden = true, direction = "float" })
	local tig = Terminal:new({ cmd = "tig", hidden = true, direction = "float" })
	local new_tab_term = Terminal:new({ cmd = "/bin/zsh", hidden = true, direction = "tab" })
	local newsboat = Terminal:new({ cmd = "newsboat", hidden = true, direction = "tab" })
	local claude_code = Terminal:new({
		cmd = "claude",
		hidden = true,
		direction = "vertical",
		size = math.floor(vim.o.columns * 0.4),
		on_open = function(term)
			vim.opt_local.relativenumber = false
			vim.opt_local.number = false
		end,
	})
	local kimi_claude_code = Terminal:new({
		cmd = "ANTHROPIC_BASE_URL=https://api.moonshot.cn/anthropic/ ANTHROPIC_API_KEY=$(cat ~/work/password/kimi-cc) claude",
		hidden = true,
		direction = "vertical",
		size = math.floor(vim.o.columns * 0.4),
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
		on_open = function(term)
			vim.opt_local.relativenumber = false
			vim.opt_local.number = false
		end,
	})
	local cursor_agent = Terminal:new({
		cmd = "cursor_agent",
		hidden = true,
		direction = "vertical",
		size = math.floor(vim.o.columns * 0.4),
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
	local function qwen_toggle()
		qwen:toggle()
	end
	local function gemini_toggle()
		gemini:toggle()
	end
	local function cursor_agent_toggle()
		cursor_agent:toggle()
	end

	local keymap = {
		{ "<leader>g", group = "Terminal", nowait = false, remap = false },
		{ "<leader>ga", lua_toggle, desc = "Lua", nowait = false, remap = false },
		{ "<leader>gc", claude_code_toggle, desc = "Claude Code", nowait = false, remap = false },
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
