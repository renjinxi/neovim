local status_ok, toggleterm = pcall(require, "toggleterm")
if not status_ok then
	return
end

toggleterm.setup({
	size = 20,
	open_mapping = [[<c-\>]],
	hide_numbers = true,
	shade_filetypes = {},
	shade_terminals = true,
	shading_factor = 2,
	start_in_insert = false,
	insert_mappings = true,
	persist_size = true,
	direction = "horizontal",
	close_on_exit = true,
	shell = vim.o.shell,
	float_opts = {
		border = "curved",
		winblend = 0,
		highlights = {
			border = "Normal",
			background = "Normal",
		},
	},
})

function _G.set_terminal_keymaps()
	local opts = { noremap = true }
	vim.api.nvim_buf_set_keymap(0, "t", "<esc>", [[<C-\><C-n>]], opts)
end

vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
local start_insert = function(term)
	vim.cmd("startinsert!")
end

local Terminal = require("toggleterm.terminal").Terminal
local lazygit = Terminal:new({ cmd = "lazygit", hidden = true, direction = "float", on_open = start_insert })
local ncdu = Terminal:new({ cmd = "ncdu --color dark", hidden = true, direction = "float", on_open = start_insert })
local htop = Terminal:new({ cmd = "htop", hidden = true, direction = "float", on_open = start_insert })
local ipython = Terminal:new({ cmd = "ipython", hidden = true })
local new_term = Terminal:new({ cmd = "/bin/zsh", hidden = true, direction = "float", on_open = start_insert })
local tig = Terminal:new({ cmd = "tig", hidden = true, direction = "float", on_open = start_insert })

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

function _NEWTERM_TOGGLE()
	new_term:toggle()
end

function _NEWTIG_TOGGLE()
	tig:toggle()
end

local status_ok, which_key = pcall(require, "which-key")
if not status_ok then
	return
end

local M = {}

function M.setup()
	local keymap = {
		g = {
			name = "Terminal",
			l = { "<cmd>lua _LAZYGIT_TOGGLE()<CR>", "Lazygit" },
			i = { "<cmd>lua _IPYTHON_TOGGLE()<CR>", "IPython" },
			n = { "<cmd>lua _NEWTERM_TOGGLE()<CR>", "New Term" },
			h = { "<cmd>lua _HTOP_TOGGLE()<CR>", "Htop" },
			u = { "<cmd>lua _NCDU_TOGGLE()<CR>", "Ncdu" },
			g = { "<cmd>lua _NEWTIG_TOGGLE() <CR>", "Tig" },
		},
	}

	which_key.register(keymap, {
		mode = "n",
		prefix = "<leader>",
		buffer = nil,
		silent = true,
		noremap = true,
		nowait = false,
	})
end

M.setup()
