local dap_exists, dap = pcall(require, "dap")
if not dap_exists then
	return
end

require("dap.ext.vscode").load_launchjs(".nvim/launch.json", nil)
require("plugins.dap.language.python")
require("plugins.dap.language.c")
require("plugins.dap.language.go")
require("plugins.dap.language.javascript")
