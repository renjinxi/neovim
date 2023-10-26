local opts = { noremap = true, silent = true }
local term_opts = { silent = true }

local keymap = vim.api.nvim_set_keymap

-- Remap space as leader key

keymap("n", "<space>", "", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

--keymap('v', '<leader>vc', require('osc52').copy_visual)
keymap("t", "<Esc>", "<C-\\><C-n>", term_opts)

-- insert mode
keymap("i", "<M-o>", "<Esc>o", opts)
keymap("i", "<M-n>", "<Esc>", opts)
keymap("n", "<M-n>", "<Esc>", opts)
keymap("v", "<M-n>", "<Esc>", opts)
keymap("c", "<M-n>", "<Esc>", opts)
keymap("t", "<M-n>", "<C-\\><C-n>", opts)
keymap("i", "<M-l>", "<Right>", opts)
keymap("i", "<M-j>", "<Down>", opts)
keymap("i", "<M-k>", "<Up>", opts)
keymap("i", "<M-h>", "<Left>", opts)
keymap("i", "<M-i>", "<Esc>I", opts)
keymap("i", "<M-e>", "<Esc>ea", opts)
keymap("i", "<M-;>", "<Esc>A", opts)
keymap("i", "<M-w>", "<Esc>wa", opts)
keymap("i", "<M-b>", "<Esc>bi", opts)
keymap("i", "<M-c>;", "<Esc>c$", opts)
keymap("i", "<M-enter>;", "<Esc>$a<enter>", opts)

local status_ok, which_key = pcall(require, "which-key")
if not status_ok then
	return
end

local n_opts = {
	mode = "n",
	prefix = "<leader>",
	buffer = nil,
	silent = true,
	noremap = true,
	nowait = false,
}
local v_opts = {
	mode = "v",
	prefix = "<leader>",
	buffer = nil,
	silent = true,
	noremap = true,
	nowait = false,
}

local some_thing_keymap = {
	v = {
		name = "Some Thing",
		l = { "<cmd>noh<cr>", "Cachel HighLight" },
		j = { "<cmd>set relativenumber<cr>", "Set Relative Number" },
		k = { "<cmd>set norelativenumber<cr>", "Cancel Relative Number" },
		h = { "<cmd>SymbolsOutline<cr>", "Toggle Symbols" },
		q = { "<cmd>q<cr>", "Close Current Tab" },
		a = { "<cmd>qa<cr>", "Exit" },
		o = { "<cmd>only<cr>", "Only Window" },
		p = { "<cmd>tabo<cr>", "Only Tab" },
		s = { "<cmd>only<cr><cmd>tabo<cr>", "Only Window Only Tab" },
		g = { "<cmd>ToggleTermToggleAll<cr>", "ToggleAllTerm" },
		u = { "<cmd>TroubleToggle<cr>", "Trouble Toggle" },
		r = { "<cmd>Format<cr>", "Format" },
		d = { "<cmd>DiffviewOpen<cr>", "Open Diff" },
		c = { "<cmd>DiffviewClose<cr>", "Close Diff" },
		E = { "<cmd>edit %<cr>", "Reload Current File" },
		e = { "<cmd>bufdo edit %<cr>", "Reload All Buffer File" },
	},
}

local tele_keymap = {
	f = {
		name = "Telescope",
		f = { "<cmd>Telescope find_files<cr>", "Find Files" },
		F = { "<cmd>lua require('telescope.builtin').find_files({no_ignore=true})<cr>", "Find Files" },
		g = { "<cmd>Telescope live_grep<cr>", "Live Grep" },
		--G = { "<cmd>lua require('telescope.builtin').live_grep({no_ignore=true})<cr>", "Find Files" },
		b = { "<cmd>Telescope buffers<cr>", "Buffers" },
		h = { "<cmd>Telescope help_tags<cr>", "Help Tags" },
		j = { "<cmd>Telescope diagnostics<cr>", "Diagnostics" },
		n = { "<cmd>Telescope command_history<cr>", "Command History" },
		s = { "<cmd>Telescope search_history<cr>", "Search History" },
		m = { "<cmd>Telescope marks<cr>", "Marks" },
		r = { "<cmd>Telescope registers<cr>", "Registers" },
		p = { "<cmd>Telescope jumplist<cr>", "Jumplist" },
		l = { "<cmd>Telescope file_browser<cr>", "File Browser" },
	},
}

local window_keymap = {
	w = {
		name = "Window",
		h = { "<C-w>h", "Move To Left" },
		l = { "<C-w>l", "Move To Right" },
		j = { "<C-w>j", "Move To Blow" },
		k = { "<C-w>k", "Move To Up" },
		H = { "<C-w>H", "Window Move To Left" },
		L = { "<C-w>L", "Window Move To Right" },
		J = { "<C-w>J", "Window Move To Blow" },
		K = { "<C-w>K", "Window Move To Up" },
		t = { "<C-w>T", "Window Move To New Tab" },
	},
}

local zen_keymap = {
	z = {
		name = "Zen Mode",
		n = { "<cmd>TZNarrow<cr>", "Narrow" },
		o = { "<cmd>TZFocus<cr>", "Focus" },
		m = { "<cmd>TZMinimalist<cr>", "Minimalist" },
		i = { "<cmd>TZAtaraxis<cr>", "Ataraxis" },
	},
}

local zen_v_keymap = {
	z = {
		name = "Zen Mode",
		n = { "<cmd>'<,'>TZNarrow<cr>", "Narrow" },
	},
}

local insert_keymap = {
	c = { "<esc>cc", "Delete Line" },
	w = { "<esc>cw", "Delete Word" },
	b = { "<esc>cb", "Delete Pre Word" },
}

local insert_opts = {
	mode = "i",
	prefix = "<M-c>",
	buffer = nil,
	silent = true,
	noremap = true,
	nowait = false,
}
which_key.register(some_thing_keymap, n_opts)
which_key.register(tele_keymap, n_opts)
which_key.register(window_keymap, n_opts)
which_key.register(zen_keymap, n_opts)
which_key.register(zen_v_keymap, v_opts)
which_key.register(insert_keymap, insert_opts)

for i = 1, 9 do
	local key = string.format("<leader>w%d", i)
	local cmd = string.format("<cmd>%dwincmd w<cr>", i)
	local desc = { desc = string.format("open window%d", i) }
	vim.keymap.set("n", key, cmd, desc)
end
vim.keymap.set("v", "<leader>c", "<Plug>OSCYankVisual")
