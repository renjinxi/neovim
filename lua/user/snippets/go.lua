local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
	-- iferr 错误处理
	s("iferr", {
		t("if err != nil {"),
		t({"", "\t"}),
		i(1, "return err"),
		t({"", "}"}),
	}),
	
	-- iferr with return
	s("iferrr", {
		t("if err != nil {"),
		t({"", "\treturn "}),
		i(1, "nil, err"),
		t({"", "}"}),
	}),
	
	-- iferr with log
	s("iferrl", {
		t("if err != nil {"),
		t({"", "\tlog.Fatal(err)"}),
		t({"", "}"}),
	}),
	
	-- iferr with panic
	s("iferrp", {
		t("if err != nil {"),
		t({"", "\tpanic(err)"}),
		t({"", "}"}),
	}),
	
	-- HTTP handler
	s("httphandler", {
		t("func "),
		i(1, "handler"),
		t("(w http.ResponseWriter, r *http.Request) {"),
		t({"", "\t"}),
		i(2, "// TODO: implement handler"),
		t({"", "}"}),
	}),
	
	-- Test function
	s("testfunc", {
		t("func Test"),
		i(1, "Function"),
		t("(t *testing.T) {"),
		t({"", "\t"}),
		i(2, "// TODO: implement test"),
		t({"", "}"}),
	}),
	
	-- Benchmark function
	s("benchfunc", {
		t("func Benchmark"),
		i(1, "Function"),
		t("(b *testing.B) {"),
		t({"", "\tfor i := 0; i < b.N; i++ {"}),
		t({"", "\t\t"}),
		i(2, "// TODO: implement benchmark"),
		t({"", "\t}"}),
		t({"", "}"}),
	}),
	
	-- JSON tag
	s("json", {
		t('`json:"'),
		i(1, "field_name"),
		t('"`'),
	}),
	
	-- Go routine
	s("go", {
		t("go func() {"),
		t({"", "\t"}),
		i(1, "// TODO: implement goroutine"),
		t({"", "}()"}),
	}),
	
	-- Select case
	s("select", {
		t("select {"),
		t({"", "case "}),
		i(1, "<-ch"),
		t(":"),
		t({"", "\t"}),
		i(2, "// TODO: handle case"),
		t({"", "default:"}),
		t({"", "\t"}),
		i(3, "// TODO: handle default"),
		t({"", "}"}),
	}),
	
	-- Main function
	s("main", {
		t("func main() {"),
		t({"", "\t"}),
		i(1, "// TODO: implement main"),
		t({"", "}"}),
	}),
	
	-- Printf
	s("printf", {
		t('fmt.Printf("'),
		i(1, "%v\\n"),
		t('", '),
		i(2, "value"),
		t(")"),
	}),
	
	-- Println
	s("println", {
		t("fmt.Println("),
		i(1, "value"),
		t(")"),
	}),
}