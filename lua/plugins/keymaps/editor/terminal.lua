local M = {}

function M.setup()
	local Terminal = require("toggleterm.terminal").Terminal
	local lazygit = Terminal:new({ cmd = "lazygit", hidden = true, direction = "float" })
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

	local function claude_code_toggle()
		claude_code:toggle()
	end

	local keymap = {
		{ "<leader>g", group = "Terminal", nowait = false, remap = false },
		{ "<leader>ga", lua_toggle, desc = "Lua", nowait = false, remap = false },
		{ "<leader>gc", claude_code_toggle, desc = "Claude Code", nowait = false, remap = false },
		{ "<leader>gh", htop_toggle, desc = "Htop", nowait = false, remap = false },
		{ "<leader>gi", ipython_toggle, desc = "IPython", nowait = false, remap = false },
		{ "<leader>gn", newterm_toggle, desc = "New Term", nowait = false, remap = false },
		{ "<leader>gt", newterm, desc = "New Tab Term", nowait = false, remap = false },
		{ "<leader>gu", ncdu_toggle, desc = "Ncdu", nowait = false, remap = false },
		{ "<leader>gr", newsboat_toggle, desc = "Newsboat", nowait = false, remap = false },
	}
	require("which-key").add(keymap)

	-- 为Claude Code终端设置特殊的键映射
	vim.api.nvim_create_autocmd("TermOpen", {
		callback = function(event)
			-- 检查是否是Claude Code终端
			if vim.bo[event.buf].buftype == "terminal" then
				local term_name = vim.api.nvim_buf_get_name(event.buf)
				if term_name:match("claude") then
					-- 在Claude Code终端中，让Esc键直接传递给终端程序
					vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = event.buf, noremap = true, silent = true })
					-- 设置简单的退出终端模式快捷键
					vim.keymap.set("t", "jj", "<C-\\><C-n>", { buffer = event.buf, noremap = true, silent = true })
					-- 保留原有的 Ctrl+\ Ctrl+n 快捷键
					vim.keymap.set(
						"t",
						"<C-\\><C-n>",
						"<C-\\><C-n>",
						{ buffer = event.buf, noremap = true, silent = true }
					)
				end
			end
		end,
	})
end

return M
