local opts = { noremap = true, silent = true }
local term_opts = { silent = true }
local keymap = vim.api.nvim_set_keymap
local open_command = "xdg-open"
if vim.fn.has("mac") == 1 then
	open_command = "open"
end
local function url_repo()
	local cursorword = vim.fn.expand("<cfile>")
	if string.find(cursorword, "^[a-zA-Z0-9-_.]*/[a-zA-Z0-9-_.]*$") then
		cursorword = "https://github.com/" .. cursorword
	end
	return cursorword or ""
end

local function open_url()
	vim.fn.jobstart({ open_command, url_repo() }, { detach = true })
end

vim.keymap.set("n", "gx", open_url, opts)
-- Remap space as leader key
keymap("n", "<space>", "", opts)
keymap("t", "<Esc>", "<C-\\><C-n>", term_opts)

require("config.keymap.some_thing")
require("config.keymap.telescope")
require("config.keymap.window")
require("config.keymap.ufo")
require("config.keymap.lazygit")
require("config.keymap.lsp")
require("config.keymap.test")
require("config.keymap.dap")
require("config.keymap.goto_preview")
require("config.keymap.bqf")
require("config.keymap.nvim_tree")
require("config.keymap.terminal")
require("config.keymap.trouble")
