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

local function lazygit_toggle()
	lazygit:toggle()
end

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

local function newtig()
	tig:toggle()
end

local function newterm()
	new_tab_term:toggle()
end

local keymap = {
	{ "<leader>g", group = "Terminal", nowait = false, remap = false },
	{ "<leader>ga", lua_toggle, desc = "Lua", nowait = false, remap = false },
	{ "<leader>gc", cling_toggle, desc = "IPython", nowait = false, remap = false },
	{ "<leader>gh", htop_toggle, desc = "Htop", nowait = false, remap = false },
	{ "<leader>gi", ipython_toggle, desc = "IPython", nowait = false, remap = false },
	{ "<leader>gn", newterm_toggle, desc = "New Term", nowait = false, remap = false },
	{ "<leader>gt", newterm, desc = "New Tab Term", nowait = false, remap = false },
	{ "<leader>gu", ncdu_toggle, desc = "Ncdu", nowait = false, remap = false },
}
require("which-key").add(keymap)
