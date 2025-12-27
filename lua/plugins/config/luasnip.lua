-- LuaSnip 配置
-- Keymaps 已迁移到 keymaps/all.lua

require("luasnip").config.set_config({
	history = true,
	updateevents = "TextChanged,TextChangedI",
})
require("luasnip.loaders.from_vscode").lazy_load()
require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/lua/user/snippets/" })
