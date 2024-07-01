local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local events = require("luasnip.util.events")
local ai = require("luasnip.nodes.absolute_indexer")
local extras = require("luasnip.extras")
local l = extras.lambda
local rep = extras.rep
local p = extras.partial
local m = extras.match
local n = extras.nonempty
local dl = extras.dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local conds = require("luasnip.extras.expand_conditions")
local postfix = require("luasnip.extras.postfix").postfix
local types = require("luasnip.util.types")
local parse = require("luasnip.util.parser").parse_snippet
local ms = ls.multi_snippet
local k = require("luasnip.nodes.key_indexer").new_key

local viewset_str_fmt = [[
from rest_framework.filters import SearchFilter
from rest_framework_filters.backends import (
    ComplexFilterBackend,
)
from utils.pagination import Pagination
from utils.viewsets import ModelViewSet

from {app}.filters import {model}Filter
from {app}.models import {model}
from {app}.serializers import {model}Serializer


class {model}ViewSet(ModelViewSet):
    pagination_class = Pagination
    filter_backends = [SearchFilter, ComplexFilterBackend]
    filter_class = {model}Filter
    serializer_class = {model}Serializer
    queryset = {model}.objects.all()
]]

local viewset_node = { app = i(1, "app name"), model = i(2, "model name") }

ls.add_snippets("all", {
	s(
		"viewset",
		fmt(viewset_str_fmt, viewset_node, {
			repeat_duplicates = true,
		})
	),
})
