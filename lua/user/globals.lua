local settings = require("user.settings")
local g = vim.g

g.python3_host_prog = settings.python3_host_prog
--g.indent_blankline_char = "¦"

---- term use a or i
----g.termdebug_use_prompt = 1
---- vista option
--g.vista_icon_indent = { "╰─▸ ", "├─▸ " }
--g.vista_default_executive = "nvim_lsp"
--g.vista_default_executive = "nvim_lsp"
-- g.vista_echo_cursor_strategy = "scroll"
g.vista_fzf_preview = { "right:50%" }
g.fzf_preview_window = { "right:50%", "ctrl-/" }
