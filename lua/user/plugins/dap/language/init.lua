local dap_exists, dap = pcall(require, "dap")
if not dap_exists then
    return
end

require("dap.ext.vscode").load_launchjs(".nvim/launch.json", nil)
require("user.plugins.dap.language.python")
require("user.plugins.dap.language.c")

