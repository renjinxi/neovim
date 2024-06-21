local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node

ls.add_snippets("all", {
	-- 这是一个简单的代码片段
	s("trigger", {
		t("This is a basic snippet"),
		i(1, "placeholder"),
	}),
})
