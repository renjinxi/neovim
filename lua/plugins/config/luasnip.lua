local ls = require("luasnip")

vim.keymap.set({ "i" }, "<C-G>", function()
	ls.expand()
end, { silent = true })
vim.keymap.set({ "i", "s" }, "<C-t>", function()
	ls.jump(1)
end, { silent = true })
vim.keymap.set({ "i", "s" }, "<C-b>", function()
	ls.jump(-1)
end, { silent = true })

vim.keymap.set({ "i", "s" }, "<C-,>", function()
	if ls.choice_active() then
		ls.change_choice(1)
	end
end, { silent = true })

require("luasnip").config.set_config({
	history = true,
	updateevents = "TextChanged,TextChangedI",
})
require("luasnip.loaders.from_vscode").lazy_load()
require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/lua/user/snippets/" })
