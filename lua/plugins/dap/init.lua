require("plugins.dap.config")
require("plugins.dap.language")
require("plugins.dap.ui")

-- 设置DAP日志级别以调试问题
local dap = require("dap")
dap.set_log_level("TRACE") -- 调试时可以打开
