-- Core configuration entry point
local M = {}

function M.setup()
    -- 加载基础选项
    require("core.options").setup()
    require("core.autocmds").setup()

end

return M 