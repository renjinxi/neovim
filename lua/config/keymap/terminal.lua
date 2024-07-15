function _G.set_terminal_keymaps()
	local opts = { noremap = true }
	vim.api.nvim_buf_set_keymap(0, "t", "<esc>", [[<C-\><C-n>]], opts)
end

vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
local start_insert = function(term)
	vim.cmd("startinsert!")
end

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

function _LAZYGIT_TOGGLE()
	lazygit:toggle()
end

function _NCDU_TOGGLE()
	ncdu:toggle()
end

function _HTOP_TOGGLE()
	htop:toggle()
end

function _IPYTHON_TOGGLE()
	ipython:toggle()
end

function _CLING_TOGGLE()
	cling:toggle()
end

function _LUA_TOGGLE()
	lua:toggle()
end

function _NEWTERM_TOGGLE()
	new_term:toggle()
end

function _NEWTIG()
	tig:toggle()
end

function _NEWTERM()
	new_tab_term:toggle()
end

local keymap = {
	{ "<leader>g", group = "Terminal", nowait = false, remap = false },
	{ "<leader>ga", "<cmd>lua __LUA_TOGGLE()<CR>", desc = "Lua", nowait = false, remap = false },
	{ "<leader>gc", "<cmd>lua _CLING_TOGGLE()<CR>", desc = "IPython", nowait = false, remap = false },
	{ "<leader>gh", "<cmd>lua _HTOP_TOGGLE()<CR>", desc = "Htop", nowait = false, remap = false },
	{ "<leader>gi", "<cmd>lua _IPYTHON_TOGGLE()<CR>", desc = "IPython", nowait = false, remap = false },
	{ "<leader>gn", "<cmd>lua _NEWTERM_TOGGLE()<CR>", desc = "New Term", nowait = false, remap = false },
	{ "<leader>gt", "<cmd>lua _NEWTERM() <CR>", desc = "New Tab Term", nowait = false, remap = false },
	{ "<leader>gu", "<cmd>lua _NCDU_TOGGLE()<CR>", desc = "Ncdu", nowait = false, remap = false },
}
require("which-key").add(keymap)
